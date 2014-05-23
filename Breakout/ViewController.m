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

#import <QuartzCore/QuartzCore.h> //for rounded view

@interface ViewController () <UICollisionBehaviorDelegate>

@property (weak, nonatomic) IBOutlet PaddleView *paddleView;
@property (weak, nonatomic) IBOutlet BallView *ballView;
@property (weak, nonatomic) IBOutlet BlockView *blockView;

@property UIDynamicAnimator *dynamicAnimator;

@property UIDynamicItemBehavior *paddleDynamicBehavior;
@property UIDynamicItemBehavior *ballDynamicBehavior;

@property UIPushBehavior *pushBehavior;

@property UICollisionBehavior *collisionBehavior;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Provides physics-related capabilities and animations for paddle and ball
    self.dynamicAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];

    // Applies a continuous or instantaneous force to dynamic items
    self.pushBehavior = [[UIPushBehavior alloc] initWithItems:@[self.ballView] mode:UIPushBehaviorModeInstantaneous];

    // Sets up properties for the pushBehavior and add it to the dynamicAnimator
    self.pushBehavior.pushDirection = CGVectorMake(0.5, 1.0);
    self.pushBehavior.active = YES;
    self.pushBehavior.magnitude = 0.2;
    [self.dynamicAnimator addBehavior:self.pushBehavior];

    // Dynamic animation configuration for paddle
    self.paddleDynamicBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.paddleView]];
    self.paddleDynamicBehavior.density = 1000;
    self.paddleDynamicBehavior.allowsRotation = NO;
    [self.dynamicAnimator addBehavior:self.paddleDynamicBehavior];

    // A dynamic item behavior represents a base dynamic animation configuration for one or more dynamic items.
    self.ballDynamicBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.ballView]];
    self.ballDynamicBehavior.allowsRotation = NO;
    self.ballDynamicBehavior.elasticity = 1.0;
    self.ballDynamicBehavior.friction = 0.0;
    self.ballDynamicBehavior.resistance = 0.0;
    [self.dynamicAnimator addBehavior:self.ballDynamicBehavior];

    // Allows items to engage in collisions with each other and with the behavior’s specified boundaries
    self.collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[self.ballView, self.paddleView, self.blockView]];
    self.collisionBehavior.collisionMode = UICollisionBehaviorModeEverything;
    self.collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
    [self.dynamicAnimator addBehavior:self.collisionBehavior];

    // Sets collision delegate to ViewController
    self.collisionBehavior.collisionDelegate = self;

    // Call rounded circle method on ballView
    [self setRoundedView:self.ballView toDiameter:15.0];

    // Add BlockView objects
    [self createBlocksForLevel1];

}

-(void)createBlocksForLevel1
{
    BlockView *blockView1 = [[BlockView alloc]initWithFrame:CGRectMake(127, 172, 55, 20)];
    [self.view addSubview:blockView1];
    blockView1.backgroundColor = [UIColor greenColor];
    [self.collisionBehavior addItem:blockView1];
}

# pragma mark - Actions

// Allows paddle to be dragged in place along y-axis
-(IBAction)dragPaddle:(UIPanGestureRecognizer *)gestureRecognizer
{
    self.paddleView.center = CGPointMake([gestureRecognizer locationInView:self.view].x, self.paddleView.center.y);
    [self.dynamicAnimator updateItemUsingCurrentState:self.paddleView];
}

# pragma mark - Delegates

// Detects collision at bottom of view and resets ball to center
-(void)collisionBehavior:(UICollisionBehavior *)behavior beganContactForItem:(id<UIDynamicItem>)item withBoundaryIdentifier:(id<NSCopying>)identifier atPoint:(CGPoint)p
{

    if (p.y > 560)
    {
        //method that returns the ball to the middle of screen
        self.pushBehavior.pushDirection = CGVectorMake(0.5, 1.0);
        self.pushBehavior.active = YES;
        self.pushBehavior.magnitude = 0.2;
        self.ballView.center = self.view.center;
        [self.dynamicAnimator updateItemUsingCurrentState:self.ballView];
    }

}

// Detects collision between two items
-(void)collisionBehavior:(UICollisionBehavior *)behavior endedContactForItem:(id<UIDynamicItem>)item1 withItem:(id<UIDynamicItem>)item2
{
    if([item2 isKindOfClass:[BlockView class]])
    {}
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
