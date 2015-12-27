//
//  ChatViewController.m
//  Chat
//
//  Created by Jesus Cagide on 12/26/15.
//  Copyright © 2015 Jesus Cagide. All rights reserved.
//

#import "ChatViewController.h"
#import "MessageTableViewCell.h"
#import "MessageTextView.h"
#import "TypingIndicatorView.h"
#import "Message.h"

#import <LoremIpsum/LoremIpsum.h>

#define DEBUG_CUSTOM_TYPING_INDICATOR 0
static NSString *MessengerCellIdentifier = @"MessengerCell";
static NSString *AutoCompletionCellIdentifier = @"AutoCompletionCell";

@interface ChatViewController ()

@property (nonatomic, strong) NSMutableArray *messages;

@property (nonatomic, strong) NSArray *users;
@property (nonatomic, strong) NSArray *channels;
@property (nonatomic, strong) NSArray *emojis;

@property (nonatomic, strong) NSArray *searchResult;
@property (nonatomic, strong) UIWindow *pipWindow;

@property (nonatomic, assign) BOOL checkForRefresh;
@property (nonatomic, assign) BOOL reloading;

@end

@implementation ChatViewController


- (id)init
{
    self = [super initWithTableViewStyle:UITableViewStylePlain];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

+ (UITableViewStyle)tableViewStyleForCoder:(NSCoder *)decoder
{
    return UITableViewStylePlain;
}

- (void)commonInit
{
    [[NSNotificationCenter defaultCenter] addObserver:self.tableView selector:@selector(reloadData) name:UIContentSizeCategoryDidChangeNotification object:nil];
    
    // Register a SLKTextView subclass, if you need any special appearance and/or behavior customisation.
    [self registerClassForTextView:[MessageTextView class]];
    
#if DEBUG_CUSTOM_TYPING_INDICATOR
    // Register a UIView subclass, conforming to SLKTypingIndicatorProtocol, to use a custom typing indicator view.
    [self registerClassForTypingIndicatorView:[TypingIndicatorView class]];
#endif
    
}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //[self showReloadAnimationAnimated:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Example's configuration
    [self configureDataSource];
    
    // SLKTVC's configuration
    self.bounces = YES;
    self.shakeToClearEnabled = YES;
    self.keyboardPanningEnabled = YES;
    self.shouldScrollToBottomAfterKeyboardShows = NO;
    self.inverted = YES;
    
    [self.leftButton setImage:[UIImage imageNamed:@"icn_upload"] forState:UIControlStateNormal];
    [self.leftButton setTintColor:[UIColor grayColor]];
    
    [self.rightButton setTitle:NSLocalizedString(@"Send", nil) forState:UIControlStateNormal];
    
    self.textInputbar.autoHideRightButton = YES;
    self.textInputbar.maxCharCount = 256;
    self.textInputbar.counterStyle = SLKCounterStyleSplit;
    self.textInputbar.counterPosition = SLKCounterPositionTop;
    
    [self.textInputbar.editorTitle setTextColor:[UIColor darkGrayColor]];
    [self.textInputbar.editorLeftButton setTintColor:[UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0]];
    [self.textInputbar.editorRightButton setTintColor:[UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0]];
    
#if !DEBUG_CUSTOM_TYPING_INDICATOR
    self.typingIndicatorView.canResignByTouch = YES;
#endif
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerClass:[MessageTableViewCell class] forCellReuseIdentifier:MessengerCellIdentifier];
    
}


- (void)configureDataSource
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < 10; i++) {
        NSInteger words = (arc4random() % 40)+1;
        
        Message *message = [Message new];
        message.username = [LoremIpsum name];
        message.text = [LoremIpsum wordsWithNumber:words];
        [array addObject:message];
    }
    
    NSArray *reversed = [[array reverseObjectEnumerator] allObjects];
    
    self.messages = [[NSMutableArray alloc] initWithArray:reversed];
    
    self.users = @[@"Allen", @"Anna", @"Alicia", @"Arnold", @"Armando", @"Antonio", @"Brad", @"Catalaya", @"Christoph", @"Emerson", @"Eric", @"Everyone", @"Steve"];
}


- (void)didLongPressCell:(UIGestureRecognizer *)gesture
{
    
    NSLog(@"did long press cell");
}


#pragma mark - Overriden Methods

- (BOOL)ignoreTextInputbarAdjustment
{
    return [super ignoreTextInputbarAdjustment];
}

- (BOOL)forceTextInputbarAdjustmentForResponder:(UIResponder *)responder
{
    if ([responder isKindOfClass:[UIAlertController class]]) {
        return YES;
    }
        return SLK_IS_IPAD;
}


- (void)didPressLeftButton:(id)sender
{
    [super didPressLeftButton:sender];
}

- (void)didPressRightButton:(id)sender
{
    [self.textView refreshFirstResponder];
    
    Message *message = [Message new];
    message.username = [LoremIpsum name];
    message.text = [self.textView.text copy];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    UITableViewRowAnimation rowAnimation = self.inverted ? UITableViewRowAnimationBottom : UITableViewRowAnimationTop;
    UITableViewScrollPosition scrollPosition = self.inverted ? UITableViewScrollPositionBottom : UITableViewScrollPositionTop;
    
    [self.tableView beginUpdates];
    [self.messages insertObject:message atIndex:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:rowAnimation];
    [self.tableView endUpdates];
    
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:scrollPosition animated:YES];
    
    // Fixes the cell from blinking (because of the transform, when using translucent cells)
    // See https://github.com/slackhq/SlackTextViewController/issues/94#issuecomment-69929927
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [super didPressRightButton:sender];
}


- (NSString *)keyForTextCaching
{
    return [[NSBundle mainBundle] bundleIdentifier];
}

- (void)didPasteMediaContent:(NSDictionary *)userInfo
{
    // Notifies the view controller when the user has pasted a media (image, video, etc) inside of the text view.
    [super didPasteMediaContent:userInfo];
    
    SLKPastableMediaType mediaType = [userInfo[SLKTextViewPastedItemMediaType] integerValue];
    NSString *contentType = userInfo[SLKTextViewPastedItemContentType];
    id data = userInfo[SLKTextViewPastedItemData];
    
    NSLog(@"%s : %@ (type = %ld) | data : %@",__FUNCTION__, contentType, (unsigned long)mediaType, data);
}


- (BOOL)canPressRightButton
{
    return [super canPressRightButton];
}


#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([tableView isEqual:self.tableView]) {
        return self.messages.count;
    }
    else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:self.tableView]) {
        return [self messageCellForRowAtIndexPath:indexPath];
    }
    else {
        return 0;
    }
}

- (MessageTableViewCell *)messageCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MessageTableViewCell *cell = (MessageTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:MessengerCellIdentifier];
    
    if (!cell.textLabel.text) {
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPressCell:)];
        [cell addGestureRecognizer:longPress];
    }
    
    Message *message = self.messages[indexPath.row];
    
    cell.titleLabel.text = message.username;
    cell.bodyLabel.text = message.text;
    
    cell.indexPath = indexPath;
    cell.usedForMessage = YES;
    
    // Cells must inherit the table view's transform
    // This is very important, since the main table view may be inverted
    cell.transform = self.tableView.transform;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:self.tableView]) {
        Message *message = self.messages[indexPath.row];
        
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        paragraphStyle.alignment = NSTextAlignmentLeft;
        
        CGFloat pointSize = [MessageTableViewCell defaultFontSize];
        
        NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:pointSize],
                                     NSParagraphStyleAttributeName: paragraphStyle};
        
        CGFloat width = CGRectGetWidth(tableView.frame)-kMessageTableViewCellAvatarHeight;
        width -= 25.0;
        
        CGRect titleBounds = [message.username boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:NULL];
        CGRect bodyBounds = [message.text boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:NULL];
        
        if (message.text.length == 0) {
            return 0.0;
        }
        
        CGFloat height = CGRectGetHeight(titleBounds);
        height += CGRectGetHeight(bodyBounds);
        height += 40.0;
        
        if (height < kMessageTableViewCellMinimumHeight) {
            height = kMessageTableViewCellMinimumHeight;
        }
        
        return height;
    }
    else {
        return kMessageTableViewCellMinimumHeight;
    }
}


#pragma mark - UIScrollViewDelegate Methods


- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (!self.reloading)
    {
        self.checkForRefresh = YES;  //  only check offset when dragging
    }
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.reloading) return;
    
    if (self.checkForRefresh) {
             if (scrollView.contentOffset.y >= -65.0f &&
                 scrollView.contentOffset.y <=  0.0f &&
                 !self.reloading)
            {
                NSLog(@"pull ");
            
        } else if ( scrollView.contentOffset.y <= -65.0f) {
            
            NSLog(@" release finish reload ");
        }
    }
    
    [super scrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [super scrollViewDidEndDragging:scrollView willDecelerate:decelerate];

    if (self.reloading) return;
    
    if (scrollView.contentOffset.y <= - 65.0f) {
            NSLog(@"reload");
            [self showReloadAnimationAnimated:YES];
            [self reloadTableViewDataSource];
        }
    self.checkForRefresh = NO;
}


#pragma mark State Changes

- (void) showReloadAnimationAnimated:(BOOL)animated
{
    self.reloading = YES;
    
    if (animated)
    {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.2];
        self.tableView.contentInset = UIEdgeInsetsMake(60.0f, 0.0f, 0.0f,
                                                       0.0f);
        [UIView commitAnimations];
    }
    else
    {
        self.tableView.contentInset = UIEdgeInsetsMake(60.0f, 0.0f, 0.0f,
                                                       0.0f);
    }
}

- (void) reloadTableViewDataSource
{
    self.reloading = YES;
    [self loadLocalChat];
}
- (void)dataSourceDidFinishLoadingNewData
{
    self.reloading = NO;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:.3];
    [self.tableView setContentInset:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
    [UIView commitAnimations];
}

- ( void) loadLocalChat{

    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < 3; i++) {
        NSInteger words = (arc4random() % 40)+1;
        
        Message *message = [Message new];
        message.username = [LoremIpsum name];
        message.text = [LoremIpsum wordsWithNumber:words];
        [array addObject:message];
    }
    
   NSArray *reversed = [[array reverseObjectEnumerator] allObjects];
    
    [self.messages addObjectsFromArray:reversed];
//     NSMutableArray *insertIndexPaths = [[NSMutableArray alloc] init];
//        for (int i = 0; i < reversed.count; i++) {
//          NSIndexPath *newPath = [NSIndexPath indexPathForRow:i inSection:0];
//            [insertIndexPaths addObject:newPath];
//    }
//     [self.tableView beginUpdates];
//     [self.tableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationTop];
//     [self.tableView endUpdates];
    
    
    NSIndexPath *path = [NSIndexPath indexPathForRow:[self.messages count] - 1 inSection:0];
    NSArray *paths = [NSArray arrayWithObject:path];
    
    [self.tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationTop];
                                                      
    [self.tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    
    [self dataSourceDidFinishLoadingNewData];
}

#pragma mark - Lifeterm

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



@end
