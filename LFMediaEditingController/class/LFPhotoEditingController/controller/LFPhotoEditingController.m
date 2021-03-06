//
//  LFPhotoEditingController.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/22.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFPhotoEditingController.h"
#import "LFMediaEditingHeader.h"
#import "UIView+LFMEFrame.h"
#import "LFMediaEditingType.h"

#import "LFEditingView.h"
#import "LFEditToolbar.h"
#import "LFStickerBar.h"
#import "LFTextBar.h"
#import "LFClipToolbar.h"


@interface LFPhotoEditingController () <LFEditToolbarDelegate, LFStickerBarDelegate, LFClipToolbarDelegate, LFTextBarDelegate, LFPhotoEditDelegate, LFEditingViewDelegate, UIActionSheetDelegate, UIGestureRecognizerDelegate>
{
    /** 编辑模式 */
    LFEditingView *_EditingView;
    
    UIView *_edit_naviBar;
    /** 底部栏菜单 */
    LFEditToolbar *_edit_toolBar;
    /** 剪切菜单 */
    LFClipToolbar *_edit_clipping_toolBar;
    
    /** 贴图菜单 */
    LFStickerBar *_edit_sticker_toolBar;
    
    /** 单击手势 */
    UITapGestureRecognizer *singleTapRecognizer;
}

/** 隐藏控件 */
@property (nonatomic, assign) BOOL isHideNaviBar;

@end

@implementation LFPhotoEditingController

- (instancetype)initWithOrientation:(UIInterfaceOrientation)orientation
{
    self = [super initWithOrientation:orientation];
    if (self) {
        _operationType = LFPhotoEditOperationType_All;
    }
    return self;
}

- (void)setEditImage:(UIImage *)editImage
{
    _editImage = editImage;
    /** GIF图片仅支持编辑第一帧 */
    if (editImage.images.count) {
        editImage = editImage.images.firstObject;
    }
    _EditingView.image = editImage;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self configScrollView];
    [self configCustomNaviBar];
    [self configBottomToolBar];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    if (@available(iOS 11.0, *)) {
        _edit_naviBar.height = kCustomTopbarHeight_iOS11;
    } else {
        _edit_naviBar.height = kCustomTopbarHeight;
    }
}

- (void)dealloc{
    [self hideProgressHUD];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 创建视图
- (void)configScrollView
{
    _EditingView = [[LFEditingView alloc] initWithFrame:self.view.bounds];
    _EditingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _EditingView.editDelegate = self;
    _EditingView.clippingDelegate = self;
    if (_photoEdit) {
        [self setEditImage:_photoEdit.editImage];
        _EditingView.photoEditData = _photoEdit.editData;
    } else {
        [self setEditImage:_editImage];
    }
    
    /** 单击的 Recognizer */
    singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singlePressed)];
    /** 点击的次数 */
    singleTapRecognizer.numberOfTapsRequired = 1; // 单击
    singleTapRecognizer.delegate = self;
    /** 给view添加一个手势监测 */
    [self.view addGestureRecognizer:singleTapRecognizer];
    
    [self.view addSubview:_EditingView];
}

- (void)configCustomNaviBar
{
    CGFloat margin = 8, topbarHeight = 0;
    if (@available(iOS 11.0, *)) {
        topbarHeight = kCustomTopbarHeight_iOS11;
    } else {
        topbarHeight = kCustomTopbarHeight;
    }
    CGFloat naviHeight = CGRectGetHeight(self.navigationController.navigationBar.frame);
    
    _edit_naviBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, topbarHeight)];
    _edit_naviBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    _edit_naviBar.backgroundColor = [UIColor colorWithRed:(34/255.0) green:(34/255.0)  blue:(34/255.0) alpha:0.7];
    
    UIView *naviBar = [[UIView alloc] initWithFrame:CGRectMake(0, topbarHeight-naviHeight, _edit_naviBar.frame.size.width, naviHeight)];
    naviBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [_edit_naviBar addSubview:naviBar];
    
    UIFont *font = [UIFont systemFontOfSize:15];
    CGFloat editCancelWidth = [self.cancelButtonTitle boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:font} context:nil].size.width + 30;
    UIButton *_edit_cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(margin, 0, editCancelWidth, naviHeight)];
    _edit_cancelButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [_edit_cancelButton setTitle:self.cancelButtonTitle forState:UIControlStateNormal];
    _edit_cancelButton.titleLabel.font = font;
    [_edit_cancelButton setTitleColor:self.cancelButtonTitleColorNormal forState:UIControlStateNormal];
    [_edit_cancelButton addTarget:self action:@selector(cancelButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [naviBar addSubview:_edit_cancelButton];
    
    CGFloat editOkWidth = [self.oKButtonTitle boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:font} context:nil].size.width + 30;

    UIButton *_edit_finishButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.width - editOkWidth-margin, 0, editOkWidth, naviHeight)];
    _edit_finishButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [_edit_finishButton setTitle:self.oKButtonTitle forState:UIControlStateNormal];
    _edit_finishButton.titleLabel.font = font;
    [_edit_finishButton setTitleColor:self.oKButtonTitleColorNormal forState:UIControlStateNormal];
    [_edit_finishButton addTarget:self action:@selector(finishButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [naviBar addSubview:_edit_finishButton];
    
    [self.view addSubview:_edit_naviBar];
}

- (void)configBottomToolBar
{
    LFEditToolbarType toolbarType = 0;
    if (self.operationType&LFPhotoEditOperationType_draw) {
        toolbarType |= LFEditToolbarType_draw;
    }
    if (self.operationType&LFPhotoEditOperationType_sticker) {
        toolbarType |= LFEditToolbarType_sticker;
    }
    if (self.operationType&LFPhotoEditOperationType_text) {
        toolbarType |= LFEditToolbarType_text;
    }
    if (self.operationType&LFPhotoEditOperationType_splash) {
        toolbarType |= LFEditToolbarType_splash;
    }
    if (self.operationType&LFPhotoEditOperationType_crop) {
        toolbarType |= LFEditToolbarType_crop;
    }
    
    _edit_toolBar = [[LFEditToolbar alloc] initWithType:toolbarType];
    _edit_toolBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    _edit_toolBar.delegate = self;
    [_edit_toolBar setDrawSliderColorAtIndex:1]; /** 红色 */
    /** 绘画颜色一致 */
    [_EditingView setDrawColor:[_edit_toolBar drawSliderCurrentColor]];
    [self.view addSubview:_edit_toolBar];
}

#pragma mark - 顶部栏(action)
- (void)singlePressed
{
    _isHideNaviBar = !_isHideNaviBar;
    [self changedBarState];
}
- (void)cancelButtonClick
{
    if ([self.delegate respondsToSelector:@selector(lf_PhotoEditingController:didCancelPhotoEdit:)]) {
        [self.delegate lf_PhotoEditingController:self didCancelPhotoEdit:self.photoEdit];
    }
}

- (void)finishButtonClick
{
    [self showProgressHUD];
    /** 取消贴图激活 */
    [_EditingView stickerDeactivated];
    
    /** 处理编辑图片 */
    __block LFPhotoEdit *photoEdit = nil;
    NSDictionary *data = [_EditingView photoEditData];
    UIImage *image = nil;
    if (data) {
        image = [_EditingView createEditImage];
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (data) {
            photoEdit = [[LFPhotoEdit alloc] initWithEditImage:self.editImage previewImage:image data:data];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(lf_PhotoEditingController:didFinishPhotoEdit:)]) {
                [self.delegate lf_PhotoEditingController:self didFinishPhotoEdit:photoEdit];
            }
            [self hideProgressHUD];
        });
    });
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isDescendantOfView:_EditingView]) {
        return YES;
    }
    return NO;
}

#pragma mark - LFEditToolbarDelegate 底部栏(action)

/** 一级菜单点击事件 */
- (void)lf_editToolbar:(LFEditToolbar *)editToolbar mainDidSelectAtIndex:(NSUInteger)index
{
    /** 取消贴图激活 */
    [_EditingView stickerDeactivated];
    
    switch (index) {
        case LFEditToolbarType_draw:
        {
            /** 关闭涂抹 */
            _EditingView.splashEnable = NO;
            /** 打开绘画 */
            _EditingView.drawEnable = !_EditingView.drawEnable;
        }
            break;
        case LFEditToolbarType_sticker:
        {
            [self singlePressed];
            [self changeStickerMenu:YES];
        }
            break;
        case LFEditToolbarType_text:
        {
            [self showTextBarController:nil];
        }
            break;
        case LFEditToolbarType_splash:
        {
            /** 关闭绘画 */
            _EditingView.drawEnable = NO;
            /** 打开涂抹 */
            _EditingView.splashEnable = !_EditingView.splashEnable;
        }
            break;
        case LFEditToolbarType_crop:
        {
            [_EditingView setIsClipping:YES animated:YES];
            [self changeClipMenu:YES];
            _edit_clipping_toolBar.enableReset = _EditingView.canReset;
        }
            break;
        default:
            break;
    }
}
/** 二级菜单点击事件-撤销 */
- (void)lf_editToolbar:(LFEditToolbar *)editToolbar subDidRevokeAtIndex:(NSUInteger)index
{
    switch (index) {
        case LFEditToolbarType_draw:
        {
            [_EditingView drawUndo];
        }
            break;
        case LFEditToolbarType_sticker:
            break;
        case LFEditToolbarType_text:
            break;
        case LFEditToolbarType_splash:
        {
            [_EditingView splashUndo];
        }
            break;
        case LFEditToolbarType_crop:
            break;
        default:
            break;
    }
}
/** 二级菜单点击事件-按钮 */
- (void)lf_editToolbar:(LFEditToolbar *)editToolbar subDidSelectAtIndex:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case LFEditToolbarType_draw:
            break;
        case LFEditToolbarType_sticker:
            break;
        case LFEditToolbarType_text:
            break;
        case LFEditToolbarType_splash:
        {
            _EditingView.splashState = indexPath.row == 1;
        }
            break;
        case LFEditToolbarType_crop:
            break;
        default:
            break;
    }
}
/** 撤销允许权限获取 */
- (BOOL)lf_editToolbar:(LFEditToolbar *)editToolbar canRevokeAtIndex:(NSUInteger)index
{
    BOOL canUndo = NO;
    switch (index) {
        case LFEditToolbarType_draw:
        {
            canUndo = [_EditingView drawCanUndo];
        }
            break;
        case LFEditToolbarType_sticker:
            break;
        case LFEditToolbarType_text:
            break;
        case LFEditToolbarType_splash:
        {
            canUndo = [_EditingView splashCanUndo];
        }
            break;
        case LFEditToolbarType_crop:
            break;
        default:
            break;
    }
    
    return canUndo;
}
/** 二级菜单滑动事件-绘画 */
- (void)lf_editToolbar:(LFEditToolbar *)editToolbar drawColorDidChange:(UIColor *)color
{
    [_EditingView setDrawColor:color];
}

#pragma mark - 剪切底部栏（懒加载）
- (UIView *)edit_clipping_toolBar
{
    if (_edit_clipping_toolBar == nil) {
        CGFloat h = 44.f;
        if (@available(iOS 11.0, *)) {
            h += self.view.safeAreaInsets.bottom;
        }
        _edit_clipping_toolBar = [[LFClipToolbar alloc] initWithFrame:CGRectMake(0, self.view.height - h, self.view.width, h)];
        _edit_clipping_toolBar.delegate = self;
    }
    return _edit_clipping_toolBar;
}

#pragma mark - LFClipToolbarDelegate
/** 取消 */
- (void)lf_clipToolbarDidCancel:(LFClipToolbar *)clipToolbar
{
    [_EditingView cancelClipping:YES];
    [self changeClipMenu:NO];
    _edit_clipping_toolBar.selectAspectRatio = NO;
    [_EditingView setAspectRatio:nil];
}
/** 完成 */
- (void)lf_clipToolbarDidFinish:(LFClipToolbar *)clipToolbar
{
    [_EditingView setIsClipping:NO animated:YES];
    [self changeClipMenu:NO];
    _edit_clipping_toolBar.selectAspectRatio = NO;
    [_EditingView setAspectRatio:nil];
}
/** 重置 */
- (void)lf_clipToolbarDidReset:(LFClipToolbar *)clipToolbar
{
    [_EditingView reset];
    _edit_clipping_toolBar.enableReset = _EditingView.canReset;
    _edit_clipping_toolBar.selectAspectRatio = NO;
    [_EditingView setAspectRatio:nil];
}
/** 旋转 */
- (void)lf_clipToolbarDidRotate:(LFClipToolbar *)clipToolbar
{
    [_EditingView rotate];
    _edit_clipping_toolBar.enableReset = _EditingView.canReset;
}
/** 长宽比例 */
- (void)lf_clipToolbarDidAspectRatio:(LFClipToolbar *)clipToolbar
{
    NSArray *items = [_EditingView aspectRatioDescs];
    if (NSClassFromString(@"UIAlertController")) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        [alertController addAction:[UIAlertAction actionWithTitle:self.cancelButtonTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            _edit_clipping_toolBar.selectAspectRatio = NO;
            [_EditingView setAspectRatio:nil];
        }]];
        
        //Add each item to the alert controller
        for (NSInteger i=0; i<items.count; i++) {
            NSString *item = items[i];
            UIAlertAction *action = [UIAlertAction actionWithTitle:item style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                _edit_clipping_toolBar.selectAspectRatio = YES;
                [_EditingView setAspectRatio:item];
            }];
            [alertController addAction:action];
        }
        
        alertController.modalPresentationStyle = UIModalPresentationPopover;
        UIPopoverPresentationController *presentationController = [alertController popoverPresentationController];
        presentationController.sourceView = clipToolbar;
        presentationController.sourceRect = clipToolbar.clickViewRect;
        [self presentViewController:alertController animated:YES completion:nil];
    }
    else {
        //TODO: Completely overhaul this once iOS 7 support is dropped
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:self.cancelButtonTitle
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:nil];
        
        for (NSString *item in items) {
            [actionSheet addButtonWithTitle:item];
        }
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            [actionSheet showFromRect:clipToolbar.frame inView:clipToolbar animated:YES];
        else
            [actionSheet showInView:self.view];
#pragma clang diagnostic pop
    }
}

#pragma mark - UIActionSheetDelegate
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == [actionSheet cancelButtonIndex]) {
        _edit_clipping_toolBar.selectAspectRatio = NO;
        [_EditingView setAspectRatio:nil];
    } else {
        _edit_clipping_toolBar.selectAspectRatio = YES;
        [_EditingView setAspectRatio:[actionSheet buttonTitleAtIndex:buttonIndex]];
    }
}
#pragma clang diagnostic pop

#pragma mark - 贴图菜单（懒加载）
- (LFStickerBar *)edit_sticker_toolBar
{
    if (_edit_sticker_toolBar == nil) {
        CGFloat w=self.view.width, h=175.f;
        if (@available(iOS 11.0, *)) {
            h += self.view.safeAreaInsets.bottom;
        }
        _edit_sticker_toolBar = [[LFStickerBar alloc] initWithFrame:CGRectMake(0, self.view.height, w, h) resourcePath:self.stickerPath];
        _edit_sticker_toolBar.delegate = self;
    }
    return _edit_sticker_toolBar;
}

#pragma mark - LFStickerBarDelegate
- (void)lf_stickerBar:(LFStickerBar *)lf_stickerBar didSelectImage:(UIImage *)image
{
    if (image) {
        [_EditingView createStickerImage:image];
    }
    [self singlePressed];
}

#pragma mark - LFTextBarDelegate
/** 完成回调 */
- (void)lf_textBarController:(LFTextBar *)textBar didFinishText:(LFText *)text
{
    if (text) {
        /** 判断是否更改文字 */
        if (textBar.showText) {
            [_EditingView changeSelectStickerText:text];
        } else {
            [_EditingView createStickerText:text];
        }
    } else {
        if (textBar.showText) { /** 文本被清除，删除贴图 */
            [_EditingView removeSelectStickerView];
        }
    }
    [self lf_textBarControllerDidCancel:textBar];
}
/** 取消回调 */
- (void)lf_textBarControllerDidCancel:(LFTextBar *)textBar
{
    /** 显示顶部栏 */
    _isHideNaviBar = NO;
    [self changedBarState];
    /** 更改文字情况才重新激活贴图 */
    if (textBar.showText) {
        [_EditingView activeSelectStickerView];
    }
    [textBar resignFirstResponder];
    
    [UIView animateWithDuration:0.25f delay:0.f options:UIViewAnimationOptionCurveLinear animations:^{
        textBar.y = self.view.height;
    } completion:^(BOOL finished) {
        [textBar removeFromSuperview];
    }];
}

#pragma mark - LFPhotoEditDelegate
#pragma mark - LFPhotoEditDrawDelegate
/** 开始绘画 */
- (void)lf_photoEditDrawBegan
{
    _isHideNaviBar = YES;
    [self changedBarState];
}
/** 结束绘画 */
- (void)lf_photoEditDrawEnded
{
    /** 撤销生效 */
    if (_EditingView.drawCanUndo) [_edit_toolBar setRevokeAtIndex:LFEditToolbarType_draw];
    
    _isHideNaviBar = NO;
    [self changedBarState];
}

#pragma mark - LFPhotoEditStickerDelegate
/** 点击贴图 isActive=YES 选中的情况下点击 */
- (void)lf_photoEditStickerDidSelectViewIsActive:(BOOL)isActive
{
    _isHideNaviBar = NO;
    [self changedBarState];
    if (isActive) { /** 选中的情况下点击 */
        LFText *text = [_EditingView getSelectStickerText];
        if (text) {
            [self showTextBarController:text];
        }
    }
}

#pragma mark - LFPhotoEditSplashDelegate
/** 开始模糊 */
- (void)lf_photoEditSplashBegan
{
    _isHideNaviBar = YES;
    [self changedBarState];
}
/** 结束模糊 */
- (void)lf_photoEditSplashEnded
{
    /** 撤销生效 */
    if (_EditingView.splashCanUndo) [_edit_toolBar setRevokeAtIndex:LFEditToolbarType_splash];
    
    _isHideNaviBar = NO;
    [self changedBarState];
}

#pragma mark - LFEditingViewDelegate
/** 剪裁发生变化后 */
- (void)lf_EditingViewDidEndZooming:(LFEditingView *)EditingView
{
    _edit_clipping_toolBar.enableReset = EditingView.canReset;
}
/** 剪裁目标移动后 */
- (void)lf_EditingViewEndDecelerating:(LFEditingView *)EditingView
{
    _edit_clipping_toolBar.enableReset = EditingView.canReset;
}

#pragma mark - private
- (void)changedBarState
{
    /** 隐藏贴图菜单 */
    [self changeStickerMenu:NO];
    
    [UIView animateWithDuration:.25f animations:^{
        CGFloat alpha = _isHideNaviBar ? 0.f : 1.f;
        _edit_naviBar.alpha = alpha;
        _edit_toolBar.alpha = alpha;
    }];
}

- (void)changeClipMenu:(BOOL)isChanged
{
    if (isChanged) {
        /** 关闭所有编辑 */
        [_EditingView photoEditEnable:NO];
        /** 切换菜单 */
        [self.view addSubview:self.edit_clipping_toolBar];
        [UIView animateWithDuration:0.25f animations:^{
            self.edit_clipping_toolBar.alpha = 1.f;
        }];
        singleTapRecognizer.enabled = NO;
        [self singlePressed];
    } else {
        if (_edit_clipping_toolBar.superview == nil) return;

        /** 开启编辑 */
        [_EditingView photoEditEnable:YES];
        
        singleTapRecognizer.enabled = YES;
        [UIView animateWithDuration:.25f animations:^{
            self.edit_clipping_toolBar.alpha = 0.f;
        } completion:^(BOOL finished) {
            [self.edit_clipping_toolBar removeFromSuperview];
        }];
        
        [self singlePressed];
    }
}

- (void)changeStickerMenu:(BOOL)isChanged
{
    if (isChanged) {
        [self.view addSubview:self.edit_sticker_toolBar];
        CGRect frame = self.edit_sticker_toolBar.frame;
        frame.origin.y = self.view.height-frame.size.height;
        [UIView animateWithDuration:.25f animations:^{
            self.edit_sticker_toolBar.frame = frame;
        }];
    } else {
        if (_edit_sticker_toolBar.superview == nil) return;
        
        CGRect frame = self.edit_sticker_toolBar.frame;
        frame.origin.y = self.view.height;
        [UIView animateWithDuration:.25f animations:^{
            self.edit_sticker_toolBar.frame = frame;
        } completion:^(BOOL finished) {
            [_edit_sticker_toolBar removeFromSuperview];
            _edit_sticker_toolBar = nil;
        }];
    }
}

- (void)showTextBarController:(LFText *)text
{
    LFTextBar *textBar = [[LFTextBar alloc] initWithFrame:CGRectMake(0, self.view.height, self.view.width, self.view.height) layout:^(LFTextBar *textBar) {
        textBar.oKButtonTitleColorNormal = self.oKButtonTitleColorNormal;
        textBar.cancelButtonTitleColorNormal = self.cancelButtonTitleColorNormal;
        textBar.oKButtonTitle = self.oKButtonTitle;
        textBar.cancelButtonTitle = self.cancelButtonTitle;
        textBar.customTopbarHeight = self->_edit_naviBar.height;
    }];
    textBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    textBar.showText = text;
    textBar.delegate = self;

    [self.view addSubview:textBar];
    
    [textBar becomeFirstResponder];
    [UIView animateWithDuration:0.25f animations:^{
        textBar.y = 0;
    } completion:^(BOOL finished) {
        /** 隐藏顶部栏 */
        _isHideNaviBar = YES;
        [self changedBarState];
    }];
}


@end
