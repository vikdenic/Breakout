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

@interface ViewController () <UICollisionBehaviorDelegate>

@property (weak, nonatomic) IBOutlet PaddleView *paddleView;
@property (weak, nonatomic) IBOutlet BallView *ballView;

@property UIDynamicAnimator *dynamicAnimator;

@property UIDynamicItemBehavior *paddleDynamicBehavior;
@property UIDynamicItemBehavior *ballDynamicBehavior;

@property UIPushBehavior *pushBehavior;

@property UICollisionBehavior *collisionBehavior;

@property UISnapBehavior *snapBehavior;

@property UIPanGestureRecognizer *gestureRecognized;

@property BOOL userIsPlaying; // Controls tapGesture to drop ball
@property NSArray *startDirection; // Randomizes each turn

@property BOOL bonusDone; // Status of bonus item
@property BOOL blocksDone; // Status of blocks

@end

@implementation ViewController{
    SystemSoundID soundEffect;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Provides physics-related capabilities and animations for paddle and ball
    self.dynamicAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];

    // Dynamic animation configuration for paddle
    self.paddleDynamicBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.paddleView]];
    self.paddleDynamicBehavior.density = 100000.0;
    self.paddleDynamicBehavior.elasticity = 0.0;
    self.paddleDynamicBehavior.allowsRotation = NO;
    [self.dynamicAnimator addBehavior:self.paddleDynamicBehavior];

    // Round edges for paddleView
    self.paddleView.clipsToBounds = YES;
    self.paddleView.layer.cornerRadius = 5.0f;

    // A dynamic item behavior represents a base dynamic animation configuration for one or more dynamic items.
    self.ballDynamicBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.ballView]];
    self.ballDynamicBehavior.allowsRotation = YES; //*
    self.ballDynamicBehavior.elasticity = 1.0;
    self.ballDynamicBehavior.friction = 0.0;
    self.ballDynamicBehavior.resistance = 0.0;
    self.ballDynamicBehavior.angularResistance = 0.0;
    [self.dynamicAnimator addBehavior:self.ballDynamicBehavior];

    // Allows items to engage in collisions with each other and with the behavior’s specified boundaries
    self.collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[self.ballView, self.paddleView]];
    self.collisionBehavior.collisionMode = UICollisionBehaviorModeEverything;
    self.collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
    [self.dynamicAnimator addBehavior:self.collisionBehavior];

    // Sets collision delegate to ViewController
    self.collisionBehavior.collisionDelegate = self;

    // Call rounded circle method on ballView
    [self setRoundedView:self.ballView toDiameter:15.0];

    // Creates BlockView objects for Level 1
    [self createBlocksForLevel1];

    // Array with float for push direction to start left or right randomly
    self.startDirection = @[@-0.5,@0.5];

    // MP3 set up for bonus blocks
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"blop" ofType:@"mp3"];
    NSURL *soundURL = [NSURL fileURLWithPath:soundPath];
    AudioServicesCreateSystemSoundID(CFBridgingRetain(soundURL), &soundEffect);

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

    // BonusImageView for special block
    blockView5.bonusImageView = [[BonusImageView alloc]initWithFrame:CGRectMake(134, 172, 50, 50)];
    [self traitsForBonuses:blockView5.bonusImageView withImage:@"sloth"];
}

// Necessary view-adding and behaviors for newly created blocks
-(void)behaviorsForNewBlocks:(BlockView *)newBlockView withColor:(UIColor *)color
{
    [self.view addSubview:newBlockView];
    newBlockView.backgroundColor = color;
    [self.collisionBehavior addItem:newBlockView];
    [self.paddleDynamicBehavior addItem:newBlockView];
}

// Necessary view adding and image naming for BonusViews
-(void)traitsForBonuses:(BonusImageView *)bonusView withImage:(NSString *)imageName
{
    [self.view addSubview:bonusView];
    bonusView.image = [UIImage imageNamed:imageName];
    bonusView.alpha = 0;
}

// Applies instantaneous push behaviors to a view
-(void)applyPushBehaviors: (UIView *)viewForBehaviors withMagnitude:(float)magFloat withDirectionX:(float)x withDirectionY:(float)y
{
    // Applies instantaneous force to dynamic items
    self.pushBehavior = [[UIPushBehavior alloc]initWithItems:@[viewForBehaviors] mode:UIPushBehaviorModeInstantaneous];
    // Sets up properties for the pushBehavior and add it to the dynamicAnimator
    self.pushBehavior.pushDirection = CGVectorMake(x,y);
    self.pushBehavior.active = YES;
    self.pushBehavior.magnitude = magFloat;
    [self.dynamicAnimator addBehavior:self.pushBehavior];
}

// Applies continuous push behaviors to a view
-(void)applyPushBehaviorsContinuous: (UIView *)viewForBehaviors withMagnitude:(float)magFloat withDirectionX:(float)x withDirectionY:(float)y
{
    // Applies a continuous force to dynamic items
    self.pushBehavior = [[UIPushBehavior alloc]initWithItems:@[viewForBehaviors] mode:UIPushBehaviorModeContinuous];
    // Sets up properties for the pushBehavior and add it to the dynamicAnimator
    self.pushBehavior.pushDirection = CGVectorMake(x,y);
    self.pushBehavior.active = YES;
    self.pushBehavior.magnitude = magFloat;
    [self.dynamicAnimator addBehavior:self.pushBehavior];
}

# pragma mark - Actions

// Allows paddle to be dragged in place along y-axis
-(IBAction)dragPaddle:(UIPanGestureRecognizer *)gestureRecognizer
{
    self.paddleView.center = CGPointMake([gestureRecognizer locationInView:self.view].x, self.paddleView.center.y);
    [self.dynamicAnimator updateItemUsingCurrentState:self.paddleView];
    self.pushBehavior.magnitude = 0.05;
}

// Drops ball from center upon tap
- (IBAction)tapGesture:(UITapGestureRecognizer *)sender;{

    if(self.userIsPlaying == NO)
    {
    [self.dynamicAnimator removeBehavior:self.snapBehavior];
    int random = arc4random_uniform(2);
    NSNumber *randomNumber = [self.startDirection objectAtIndex:random];
    CGFloat randomFloat = [randomNumber floatValue];
    [self applyPushBehaviors:self.ballView withMagnitude:0.08 withDirectionX:randomFloat withDirectionY:-1.0];
    self.userIsPlaying = YES;
    }
}

# pragma mark - Delegates

// Detects collision at bottom of view and resets ball to center
-(void)collisionBehavior:(UICollisionBehavior *)behavior beganContactForItem:(id<UIDynamicItem>)item withBoundaryIdentifier:(id<NSCopying>)identifier atPoint:(CGPoint)p
{
    if (p.y > 560)
    {
        //returns the ball to paddle lanch area
        self.snapBehavior = [[UISnapBehavior alloc] initWithItem:self.ballView snapToPoint:CGPointMake(155, 474)];

        //"snaps" ball back
        self.snapBehavior.damping = 1.0;
        [self.dynamicAnimator addBehavior:self.snapBehavior];
        self.userIsPlaying = NO;
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
            AudioServicesPlaySystemSound(soundEffect);
            [self applyPushBehaviorsContinuous:blockCollided.bonusImageView withMagnitude:0.3 withDirectionX:0.0 withDirectionY:1.0];

            [self.collisionBehavior addItem:blockCollided.bonusImageView];
        }
    }
    // When bonus image hits block
    if ([item1 isKindOfClass:[BonusImageView class]] && [item2 isKindOfClass:[BlockView class]])
    {
        BlockView *blockCollided = (BlockView *)item2;
        [self removeBlockAndRelatedBehaviors:blockCollided];
    }

    // When paddle catches bonus image
    if ([item1 isKindOfClass:[PaddleView class]] && [item2 isKindOfClass:[BonusImageView class]])
    {
        BonusImageView *bonusCollided = (BonusImageView *)item2;
        [self removeBlockAndRelatedBehaviors:bonusCollided];
    }
}

// Helper for removal of blocks in Collision Delegate
-(void)removeBlockAndRelatedBehaviors: (id)blockRemoved
{
    [blockRemoved removeFromSuperview];
    [self.collisionBehavior removeItem:blockRemoved];
    [self.paddleDynamicBehavior removeItem:blockRemoved];
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
