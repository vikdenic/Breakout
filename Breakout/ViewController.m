//
//  ViewController.m
//  Breakout
//
//  Created by Vik Denic on 5/22/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

#import "ViewController.h"
#import "PaddleView.h"
#import "BallView.h"
#import "BlockView.h"
#import "BonusImageView.h"

#import <QuartzCore/QuartzCore.h> //for rounded view
#import <AudioToolbox/AudioToolbox.h>

@interface ViewController () <UICollisionBehaviorDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet PaddleView *paddleView;
@property (weak, nonatomic) IBOutlet BallView *ballView;

@property UIDynamicAnimator *dynamicAnimator1;

@property UIDynamicItemBehavior *paddleDynamicBehavior;
@property UIDynamicItemBehavior *ballDynamicBehavior;
@property UIDynamicItemBehavior *bonusDynamicBehavior;

@property UIPushBehavior *pushBehavior;

@property UICollisionBehavior *collisionBehavior1; //for collision between paddle, ball, and blocks
@property UICollisionBehavior *collisionBehavior2; //for collision between paddle, ball, and bonuses

@property UISnapBehavior *snapBehavior;

@property UIPanGestureRecognizer *gestureRecognized;

@property BOOL userIsPlaying; // Controls tapGesture to drop ball

@property CGPoint tappedScreen;

@property (weak, nonatomic) IBOutlet UILabel *livesLabel;
@property int livesReamining;
@property int blocksCount;

@property NSArray *animals;

@end

@implementation ViewController{
    SystemSoundID soundEffect;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Provides physics-related capabilities and animations for paddle and ball
    self.dynamicAnimator1 = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];

    // Dynamic animation configuration for paddle
    self.paddleDynamicBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.paddleView]];
    self.paddleDynamicBehavior.density = 100000.0;
    self.paddleDynamicBehavior.elasticity = 0.0;
    self.paddleDynamicBehavior.allowsRotation = NO;
    [self.dynamicAnimator1 addBehavior:self.paddleDynamicBehavior];

    // A dynamic item behavior represents a base dynamic animation configuration for one or more dynamic items
    self.ballDynamicBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.ballView]];
    self.ballDynamicBehavior.allowsRotation = YES;
    self.ballDynamicBehavior.elasticity = 1.0;
    self.ballDynamicBehavior.friction = 0.0;
    self.ballDynamicBehavior.resistance = 0.0;
    self.ballDynamicBehavior.angularResistance = 0.0;
    [self.dynamicAnimator1 addBehavior:self.ballDynamicBehavior];

    // Dynamic animation configuration for bonuses (or, BonusImageView references)
    self.bonusDynamicBehavior = [[UIDynamicItemBehavior alloc] init];
    self.bonusDynamicBehavior.allowsRotation = YES;
    self.bonusDynamicBehavior.density = 1.0;
    self.bonusDynamicBehavior.elasticity = 1.0;
    self.bonusDynamicBehavior.friction = 0.0;
    self.bonusDynamicBehavior.resistance = 0.0;
    self.bonusDynamicBehavior.angularResistance = 0.0;
    [self.dynamicAnimator1 addBehavior:self.bonusDynamicBehavior];

    // Allows items to engage in collisions with each other and with the behavior’s specified boundaries
    // collisionBehavior1 is for the paddle, ball, and blocks
    self.collisionBehavior1 = [[UICollisionBehavior alloc] initWithItems:@[self.ballView, self.paddleView]];
    self.collisionBehavior1.collisionMode = UICollisionBehaviorModeEverything;
    self.collisionBehavior1.translatesReferenceBoundsIntoBoundary = YES;
    [self.dynamicAnimator1 addBehavior:self.collisionBehavior1];
    // Sets collision delegate to ViewController
    self.collisionBehavior1.collisionDelegate = self;

    // Allows items to engage in collisions with each other and with the behavior’s specified boundaries
    // collisionBehavior1 is for the paddle, ball, and bonuses
    self.collisionBehavior2 = [[UICollisionBehavior alloc] initWithItems:@[self.ballView, self.paddleView]];
    self.collisionBehavior2.collisionMode = UICollisionBehaviorModeEverything;
    self.collisionBehavior2.translatesReferenceBoundsIntoBoundary = YES;
    [self.dynamicAnimator1 addBehavior:self.collisionBehavior2];
    // Sets collision delegate to ViewController
    self.collisionBehavior2.collisionDelegate = self;


    // Call rounded circle method on ballView
    [self setRoundedView:self.ballView toDiameter:15.0];

    // Round edges for paddleView
    self.paddleView.clipsToBounds = YES;
    self.paddleView.layer.cornerRadius = 5.0f;

    // MP3 set up for bonus blocks
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"blop" ofType:@"mp3"];
    NSURL *soundURL = [NSURL fileURLWithPath:soundPath];
    AudioServicesCreateSystemSoundID(CFBridgingRetain(soundURL), &soundEffect);

    // Creates BlockView objects for Level 1
    [self createBlocksForLevel1];

    self.livesReamining = 3;
    self.blocksCount = 5;
}

#pragma mark - Helper Methods

// New blocks for Level 1, with color, placement, and behaviors
-(void)createBlocksForLevel1
{
    BlockView *blockView1 = [[BlockView alloc]initWithFrame:CGRectMake(62, 172, 55, 20)];
    [self behaviorsForNewBlocks:blockView1 withColor:[UIColor orangeColor]];

    BlockView *blockView2 = [[BlockView alloc]initWithFrame:CGRectMake(134, 138, 55, 20)];
    [self behaviorsForNewBlocks:blockView2 withColor:[UIColor orangeColor]];

    BlockView *blockView3 = [[BlockView alloc]initWithFrame:CGRectMake(206, 172, 55, 20)];
    [self behaviorsForNewBlocks:blockView3 withColor:[UIColor orangeColor]];

    BlockView *blockView4 = [[BlockView alloc]initWithFrame:CGRectMake(134, 207, 55, 20)];
    [self behaviorsForNewBlocks:blockView4 withColor:[UIColor orangeColor]];

    BlockView *blockView5 = [[BlockView alloc]initWithFrame:CGRectMake(134, 172, 55, 20)];
    [self behaviorsForNewBlocks:blockView5 withColor:[UIColor whiteColor]];

    // Instantiates random animal array and generates random bonus for block5
    self.animals = @[@"monkey", @"hippo", @"sloth"];
    int random = arc4random_uniform(3);
    NSString *bonusAnimal = [self.animals objectAtIndex:random];

    // BonusImageView for special block
    blockView5.bonusImageView = [[BonusImageView alloc]initWithFrame:CGRectMake(134, 172, 50, 50)];
    [self traitsForBonuses:blockView5.bonusImageView withImage:bonusAnimal withName:bonusAnimal];
    NSLog(@"%@",bonusAnimal);
}

// Necessary view-adding and behaviors for newly created blocks
-(void)behaviorsForNewBlocks:(BlockView *)newBlockView withColor:(UIColor *)color
{
    [self.view addSubview:newBlockView];
    newBlockView.backgroundColor = color;
    [self.collisionBehavior1 addItem:newBlockView];
    [self.paddleDynamicBehavior addItem:newBlockView];
}

// Necessary view adding and image naming for BonusViews
-(void)traitsForBonuses:(BonusImageView *)bonusView withImage:(NSString *)imageName withName:(NSString *)name
{
    [self.view addSubview:bonusView];
    bonusView.image = [UIImage imageNamed:imageName];
    bonusView.alpha = 0;
    bonusView.bonusName = name;
}

// Removal of blocks in Collision Delegate
-(void)removeBlockAndRelatedBehaviors: (id)blockRemoved
{
    [blockRemoved removeFromSuperview];
    [self.collisionBehavior1 removeItem:blockRemoved];
    [self.paddleDynamicBehavior removeItem:blockRemoved];

    self.blocksCount -= 1;
    if(self.blocksCount == 0)
    {
        [self wonAlertView];
    }
}

// Removal of bonus images in Collision Delegate
-(void)removeBonusAndRelatedBehaviors: (id)bonusRemoved
{
    [bonusRemoved removeFromSuperview];
    [self.bonusDynamicBehavior removeItem:bonusRemoved];
    [self.collisionBehavior2 removeItem:bonusRemoved];

}

// Alert view for lost game
-(void)wonAlertView
{
    UIAlertView *wonAlertView = [[UIAlertView alloc]initWithTitle:@"LEVEL DEFEATED"
                                                           message:@"Unlocked Level 2"
                                                          delegate:self
                                                 cancelButtonTitle:@"Continue"
                                                 otherButtonTitles: nil];
    [wonAlertView show];
    [self snapBackBall];

}

// Alert view for lost game
-(void)lostAlertView
{
    UIAlertView *lostAlertView = [[UIAlertView alloc]initWithTitle:@"GAME OVER"
                                                                    message:@"Play Again?"
                                                                   delegate:self
                                                          cancelButtonTitle:@"Exit"
                                                          otherButtonTitles:@"Play Again", nil];
    [lostAlertView show];
    [self snapBackBall];
    [self.dynamicAnimator1 removeBehavior:self.snapBehavior];

}

// Applies continuous push behaviors to bonus views
-(void)applyPushBehaviorsContinuous: (UIView *)viewForBehaviors withMagnitude:(float)magFloat withDirectionX:(float)x withDirectionY:(float)y
{
    // Applies a continuous force to dynamic items
    self.pushBehavior = [[UIPushBehavior alloc]initWithItems:@[viewForBehaviors] mode:UIPushBehaviorModeContinuous];
    // Sets up properties for the pushBehavior and add it to the dynamicAnimator
    self.pushBehavior.pushDirection = CGVectorMake(x,y);
    self.pushBehavior.active = YES;
    self.pushBehavior.magnitude = magFloat;
    [self.dynamicAnimator1 addBehavior:self.pushBehavior];
}

// Applies instantaneous push behaviors to ball
-(void)applyPushBehaviors: (UIView *)viewForBehaviors withMagnitude:(float)magFloat withDirectionX:(float)x withDirectionY:(float)y
{
    // Applies instantaneous force to dynamic items
    self.pushBehavior = [[UIPushBehavior alloc]initWithItems:@[viewForBehaviors] mode:UIPushBehaviorModeInstantaneous];
    // Sets up properties for the pushBehavior and add it to the dynamicAnimator
    self.pushBehavior.pushDirection = CGVectorMake(x,y);
    self.pushBehavior.active = YES;
    self.pushBehavior.magnitude = magFloat;
    [self.dynamicAnimator1 addBehavior:self.pushBehavior];
    self.userIsPlaying = YES;
}

# pragma mark - Actions

// Allows paddle to be dragged in place along y-axis
-(IBAction)dragPaddle:(UIPanGestureRecognizer *)gestureRecognizer
{
    self.paddleView.center = CGPointMake([gestureRecognizer locationInView:self.view].x, self.paddleView.center.y);
    [self.dynamicAnimator1 updateItemUsingCurrentState:self.paddleView];
}

// Launches ball from paddle upon tap
- (IBAction)tapGesture:(UITapGestureRecognizer *)sender
{
    if(self.userIsPlaying == NO)
    {
        [self.dynamicAnimator1 removeBehavior:self.snapBehavior];
        self.tappedScreen = [sender locationInView:self.view];

        if(self.tappedScreen.x < 160)
        {
            [self applyPushBehaviors:self.ballView withMagnitude:0.08 withDirectionX:-0.5 withDirectionY:-1.0];
        }
        else if (self.tappedScreen.x > 160)
        {
            [self applyPushBehaviors:self.ballView withMagnitude:0.08 withDirectionX:0.5 withDirectionY:-1.0];        }
    }
}

-(void)snapBackBall
{
    // Returns the ball to paddle lanch area
    self.snapBehavior = [[UISnapBehavior alloc] initWithItem:self.ballView snapToPoint:CGPointMake(155, 425)];

    // "Snaps" ball back
    self.snapBehavior.damping = 0.8;
    [self.dynamicAnimator1 addBehavior:self.snapBehavior];
}

# pragma mark - Delegates

// Detects collision at bottom of view and resets ball to center
-(void)collisionBehavior:(UICollisionBehavior *)behavior beganContactForItem:(id<UIDynamicItem>)item withBoundaryIdentifier:(id<NSCopying>)identifier atPoint:(CGPoint)p
{
    if (p.y > 450 && self.userIsPlaying == YES)
    {
        [self snapBackBall];

        // Enables tap gesture to execute
        self.userIsPlaying = NO;

        self.livesReamining -= 1;
        self.livesLabel.text = [NSString stringWithFormat:@"%d", self.livesReamining];

        if(self.livesReamining == 0)
        {
            [self lostAlertView];
        }
    }
}

// Detects collision between a ball and block
-(void)collisionBehavior:(UICollisionBehavior *)behavior endedContactForItem:(id<UIDynamicItem>)item1 withItem:(id<UIDynamicItem>)item2
{
    // When ball hits block
    if ([item1 isKindOfClass:[BallView class]] && [item2 isKindOfClass:[BlockView class]]) // If ball collides with block
    {
        BlockView *blockCollided = (BlockView *)item2;
        [self removeBlockAndRelatedBehaviors:blockCollided];

        // When ball hits bonus block
        if(blockCollided.bonusImageView)
        {
            blockCollided.bonusImageView.alpha = 1;
            [self applyPushBehaviorsContinuous:blockCollided.bonusImageView withMagnitude:0.3 withDirectionX:0.0 withDirectionY:1.0];
            [self.bonusDynamicBehavior addItem:blockCollided.bonusImageView];
            [self.collisionBehavior2 addItem:blockCollided.bonusImageView];
            AudioServicesPlaySystemSound(soundEffect);
        }
    }
    // When paddle catches bonus image
    if ([item1 isKindOfClass:[PaddleView class]] && [item2 isKindOfClass:[BonusImageView class]])
    {
        BonusImageView *bonusCollided = (BonusImageView *)item2;
        [self removeBonusAndRelatedBehaviors:bonusCollided];

        // Modify game depending on bonus animal
        if([bonusCollided.bonusName isEqual: @"monkey"])
        {
        [self setRoundedView:self.ballView toDiameter:30.0];
        self.ballView.backgroundColor = [UIColor yellowColor];
        }

        else if([bonusCollided.bonusName isEqual: @"sloth"])
        {
            self.pushBehavior.magnitude = 0.01;
            [self.dynamicAnimator1 addBehavior:self.pushBehavior];
        }

        else if([bonusCollided.bonusName isEqual: @"hippo"])
        {
            self.ballView.backgroundColor = [UIColor colorWithRed:0.905 green:0.0 blue:0.552 alpha:1.0];
            CGRect newFrame = self.view.frame;
            newFrame.size.width = 30;
            newFrame.size.height = 30;
            self.ballView.frame = newFrame;
        }
    }
}

// Allows alert view "Delete" button to remove task
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{

    if (buttonIndex == 1)
    {
        for(BlockView *block in self.view.subviews)
        {
            if([block isKindOfClass:[BlockView class]])
            {
                [block removeFromSuperview];
            }
        }
        // Reset Level
        [self.dynamicAnimator1 removeBehavior:self.snapBehavior];
        [self createBlocksForLevel1];
        self.livesReamining = 3;
        self.livesLabel.text = [NSString stringWithFormat:@"%d", self.livesReamining];
        self.blocksCount = 5;
    }
}

# pragma mark - Quartz Framework

// Method for rounded BallView
-(void)setRoundedView:(BallView *)roundedView toDiameter:(float)newSize;
{
    CGPoint saveCenter = roundedView.center;
    CGRect newFrame = CGRectMake(roundedView.frame.origin.x, roundedView.frame.origin.y, newSize, newSize);
    roundedView.frame = newFrame;
    roundedView.layer.cornerRadius = newSize / 2.0;
    roundedView.center = saveCenter;
}

@end
