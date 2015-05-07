//
//  CalendarView.m
//  ios_calendar
//
//  Created by Maxim on 10/7/13.
//  Copyright (c) 2013 Maxim. All rights reserved.
//

#import "CalendarView.h"
#import "NSDate+CalendarView.h"
#import "NSString+CalendarView.h"

#import <CoreText/CoreText.h>

//static const CGFloat CalendarViewDayCellWidth       = 35;
//static const CGFloat CalendarViewDayCellHeight      = 35; // 35
//static const CGFloat CalendarViewDayCellOffset      = 5;  // 5

//static const CGFloat CalendarViewMonthCellWidth     = 90;
//static const CGFloat CalendarViewMonthCellHeight    = 30;
static const CGFloat CalendarViewMonthTitleOffsetY  = 35;// 50
//static const CGFloat CalendarViewMonthYStep         = 60;
static const NSInteger CalendarViewMonthInLine      = 3;

static const CGFloat CalendarViewYearCellWidth      = 54;
//static const CGFloat CalendarViewYearCellHeight     = 30;
static const CGFloat CalendarViewYearTitleOffsetY   = 40; //50
//static const CGFloat CalendarViewYearYStep          = 45;
static const NSInteger CalendarViewYearsAround      = 12;
static const NSInteger CalendarViewYearsInLine      = 5;

//static const CGFloat CalendarViewMonthLabelWidth    = 100;
//static const CGFloat CalendarViewMonthLabelHeight   = 20;

//static const CGFloat CalendarViewYearLabelWidth     = 40;
//static const CGFloat CalendarViewYearLabelHeight    = 20;

static const CGFloat CalendarViewWeekDaysYOffset    = 30;
static const CGFloat CalendarViewDaysYOffset        = 60;

static NSString * const CalendarViewDefaultFont     = @"HelveticaNeue-Thin"; //@"TrebuchetMS"
static const CGFloat CalendarViewDayFontSize        = 16;
static const CGFloat CalendarViewHeaderFontSize     = 18;

static const NSInteger CalendarViewDaysInWeek       = 7;
static const NSInteger CalendarViewMonthInYear      = 12;
static const NSInteger CalendarViewMaxLinesCount    = 6;

static const CGFloat CalendarViewSelectionRound     = 3.0;

static const NSTimeInterval CalendarViewSwipeMonthFadeInTime  = 0.2;
static const NSTimeInterval CalendarViewSwipeMonthFadeOutTime = 0.3;

@implementation CalendarViewRect

@end

@interface CalendarView ()
- (void)setup;

- (void)generateDayRects;
- (void)generateMonthRects;
- (void)generateYearRects;

- (void)drawCircle:(CGRect)rect toContext:(CGContextRef *)context;
- (void)drawRoundedRectangle:(CGRect)rect toContext:(CGContextRef *)context;
- (void)drawWeekDays;

- (void)leftSwipe:(UISwipeGestureRecognizer *)recognizer;
- (void)rightSwipe:(UISwipeGestureRecognizer *)recognizer;
- (void)pinch:(UIPinchGestureRecognizer *)recognizer;
- (void)tap:(UITapGestureRecognizer *)recognizer;
- (void)doubleTap:(UITapGestureRecognizer *)recognizer;

- (void)changeDateEvent;

- (NSDictionary *)generateAttributes:(NSString *)fontName withFontSize:(CGFloat)fontSize withColor:(UIColor *)color withAlignment:(NSTextAlignment)textAlignment;
- (BOOL)checkPoint:(CGPoint)point inArray:(NSMutableArray *)array andSetValue:(NSInteger *)value;
- (void)fade;

@end

@implementation CalendarView {
    CGFloat CalendarViewDayCellWidth;
    CGFloat CalendarViewDayCellHeight;
    CGFloat CalendarViewDayCellOffset;
    
    CGFloat CalendarViewMonthCellWidth;
    CGFloat CalendarViewMonthCellHeight;
//    CGFloat CalendarViewMonthTitleOffsetY;// 50
    CGFloat CalendarViewMonthYStep;
    
//    CGFloat CalendarViewYearCellWidth;
    CGFloat CalendarViewYearCellHeight;
//    CGFloat CalendarViewYearTitleOffsetY; //50
    CGFloat CalendarViewYearYStep;
    
    CGFloat CalendarViewMonthLabelWidth;
    CGFloat CalendarViewMonthLabelHeight;
    
    CGFloat CalendarViewYearLabelWidth;
    CGFloat CalendarViewYearLabelHeight;
    
//    CGFloat CalendarViewWeekDaysYOffset;
//    CGFloat CalendarViewDaysYOffset;
}

@synthesize currentDate = _currentDate;
@synthesize maxType;
@synthesize bgColor;

#pragma mark - Initialization

- (id)init
{
	self = [self initWithPosition:0.0 y:0.0];
	return self;
}

- (id)initWithPosition:(CGFloat)x y:(CGFloat)y
{
	const CGFloat width = (CalendarViewDayCellWidth + CalendarViewDayCellOffset) * CalendarViewDaysInWeek;
	const CGFloat height = (CalendarViewDayCellHeight + CalendarViewDayCellOffset) * CalendarViewMaxLinesCount + CalendarViewDaysYOffset;
	
    self = [self initWithFrame:CGRectMake(x, y, width, height)];
	
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupConstValues:frame];
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self setupConstValues:self.frame];
    [self setup];
}

- (void)dealloc
{
    self.currentDate = nil;
    self.fontColor = nil;
    self.fontHeaderColor = nil;
    self.fontSelectedColor = nil;
    self.selectionColor = nil;
}

#pragma mark - Setup
- (void)setupConstValues:(CGRect)frame {
    CGFloat with = frame.size.width;
    CGFloat height = frame.size.height;
    
    
    CalendarViewDayCellOffset = MIN(with*.03, height*.03); // 3% of with/height
    CalendarViewDayCellWidth = (with-CalendarViewDayCellOffset*(CalendarViewDaysInWeek+3))/CalendarViewDaysInWeek;
    CalendarViewDayCellHeight = (height-CalendarViewMonthTitleOffsetY)/CalendarViewDaysInWeek;
    
//    CalendarViewMonthCellHeight = ((height-CalendarViewMonthTitleOffsetY)/(12/CalendarViewMonthInLine))*.9;
    NSInteger countMonthRows = 12/CalendarViewMonthInLine;
    CalendarViewMonthLabelHeight = CalendarViewDayFontSize*2;
    CalendarViewMonthLabelWidth = with/CalendarViewMonthInLine; // september
    CalendarViewMonthCellHeight = CalendarViewDayFontSize*2;
    CalendarViewMonthCellWidth  = CalendarViewMonthLabelWidth;
    CalendarViewMonthYStep = (height-CalendarViewMonthTitleOffsetY)/countMonthRows;

    NSInteger countYearRows = (CalendarViewYearsAround*2+1)/CalendarViewYearsInLine;
    CalendarViewYearLabelWidth = CalendarViewDayFontSize*5; // 4 letters
    CalendarViewYearLabelHeight = CalendarViewDayFontSize*2;
    CalendarViewYearCellHeight = CalendarViewDayFontSize*2;
    CalendarViewYearYStep = (height-CalendarViewMonthTitleOffsetY)/countYearRows;
    
//    static const CGFloat CalendarViewDayCellWidth       = 35;
//    static const CGFloat CalendarViewDayCellHeight      = 35;
//    static const CGFloat CalendarViewDayCellOffset      = 5;
    
//    static const CGFloat CalendarViewMonthCellWidth     = 90;
//    static const CGFloat CalendarViewMonthCellHeight    = 30;
//    static const CGFloat CalendarViewMonthTitleOffsetY  = 35;// 50
//    static const CGFloat CalendarViewMonthYStep         = 60;
    
//    static const CGFloat CalendarViewYearCellWidth      = 54;
//    static const CGFloat CalendarViewYearCellHeight     = 30;
//    static const CGFloat CalendarViewYearTitleOffsetY   = 40; //50
//    static const CGFloat CalendarViewYearYStep          = 45;
    
//    static const CGFloat CalendarViewMonthLabelWidth    = 100;
//    static const CGFloat CalendarViewMonthLabelHeight   = 20;
    
//    static const CGFloat CalendarViewYearLabelWidth     = 40;
//    static const CGFloat CalendarViewYearLabelHeight    = 20;
    
//    static const CGFloat CalendarViewWeekDaysYOffset    = 30;
//    static const CGFloat CalendarViewDaysYOffset        = 60;
    
    NSLog(@"SETUP CONST VALUES %@ \nCalendarViewDayCellOffset %f \nCalendarViewDayCellWidth %f \nCalendarViewDayCellHeight %f \nCalendarViewMonthCellHeight %f \nCalendarViewMonthYStep %f\nCalendarViewYearCellHeight %f \nCalendarViewYearYStep %f \n", NSStringFromCGRect(frame), CalendarViewDayCellOffset, CalendarViewDayCellWidth, CalendarViewDayCellHeight, CalendarViewMonthCellHeight, CalendarViewMonthYStep, CalendarViewYearCellHeight, CalendarViewYearYStep);
}
- (void)setup
{
    self.layer.masksToBounds = YES;
    
    maxType = CT_Count;

    dayRects = [[NSMutableArray alloc] init];
    monthRects = [[NSMutableArray alloc] init];
    yearRects = [[NSMutableArray alloc] init];
    
    yearTitleRect = CGRectMake(0, 0, 0, 0);
    monthTitleRect = CGRectMake(0, 0, 0, 0);
    
    self.fontColor = [UIColor blackColor];
    self.fontHeaderColor = [UIColor redColor];
    self.fontSelectedColor = [UIColor whiteColor];
    self.selectionColor = [UIColor redColor];
    bgColor = [UIColor clearColor];
    
    event = CE_None;
    
    [self setMode:CM_Default];
    
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:now];
    
    currentDay = [components day];
    currentMonth = [components month];
    currentYear = [components year];
    
    UISwipeGestureRecognizer *left = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(leftSwipe:)];
    [left setDirection:UISwipeGestureRecognizerDirectionLeft];
    [self addGestureRecognizer:left];
    
    UISwipeGestureRecognizer *right = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(rightSwipe:)];
    [right setDirection:UISwipeGestureRecognizerDirectionRight];
    [self addGestureRecognizer:right];
    
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];
    [self addGestureRecognizer:pinch];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    tap.numberOfTapsRequired = 1;
    [self addGestureRecognizer:tap];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    [self addGestureRecognizer:doubleTap];
    
    [self generateDayRects];
    [self generateMonthRects];
    [self generateYearRects];
}

- (void)setMode:(NSInteger)m
{
    mode = m;
    switch (mode) {
        case CM_Default:
        {
            type = CTDay;
            minType = CTDay;
        }
        break;
        case CM_MonthsAndYears:
        {
            type = CTMonth;
            minType = CTMonth;
        }
        break;
        case CM_Years:
        {
            type = CTYear;
            minType = CTYear;
        }
        break;
            
        default:
            break;
    }
}

#pragma mark - Public
- (NSInteger)viewType {
    return type;
}
- (void)setViewType:(NSInteger)viewType {
    if (type != viewType) {
        if (type < viewType) { // fade out
            
            type = viewType;
            [self fadeOut];
        
        } else {                // fade in
            
            type = viewType;
            [self fadeIn];
        }
    }
}

#pragma mark - Getting, setting current date

- (void)setCurrentDate:(NSDate *)date
{
    if (date) {
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *components = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:date];
        currentDay = [components day];
        currentMonth = [components month];
        currentYear = [components year];
        
        switch (type) {
            case CTDay:
                [self generateDayRects];
                break;
            case CTYear:
                [self generateYearRects];
                break;
            default:
                break;
        }
        
        [self fade];
        
        _currentDate = date;
    }
}

- (NSDate *)currentDate
{
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	[calendar setTimeZone:timeZone];
	NSDateComponents *components = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:[NSDate date]];
	[components setYear:currentYear];
	[components setMonth:currentMonth];
	[components setDay:currentDay];
	[components setHour:0];
	[components setMinute:0];
	[components setSecond:0];
	[components setTimeZone:timeZone];
	
	return [calendar dateFromComponents:components];
}

#pragma mark - Generating of rects

- (void)generateDayRects
{
	[dayRects removeAllObjects];
	
	NSDate *now = [NSDate date];
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *components = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:now];
	[components setYear:currentYear];
	[components setMonth:currentMonth];
	[components setDay:1];  // set first day of month
	
    NSDate *currentDate = [calendar dateFromComponents:components];
	NSUInteger lastDayOfMonth = [currentDate getLastDayOfMonth];
    if (currentDay > lastDayOfMonth) {
        currentDay = lastDayOfMonth;
    }
    
    [components setDay:currentDay];
    currentDate = [calendar dateFromComponents:components];
    NSInteger weekday = [currentDate getWeekdayOfFirstDayOfMonth];
	
	const CGFloat yOffSet = CalendarViewDaysYOffset;
	const CGFloat w = CalendarViewDayCellWidth;
	const CGFloat h = CalendarViewDayCellHeight;
	
	CGFloat x = 0;
	CGFloat y = yOffSet;
	
	NSInteger xi = weekday - 1;
	NSInteger yi = 0;
	
	for (NSInteger i = 1; i <= lastDayOfMonth; ++i) {
		x = xi * (CalendarViewDayCellWidth + CalendarViewDayCellOffset);
		++xi;
		
        CalendarViewRect *dayRect = [[CalendarViewRect alloc] init];
        dayRect.value = i;
        dayRect.str = [NSString stringWithFormat:@"%ld", (long)i];
        dayRect.frame = CGRectMake(x, y, w, h);
        [dayRects addObject:dayRect];
        
		if (xi >= CalendarViewDaysInWeek) {
			xi = 0;
			++yi;
			y = yOffSet + yi * (CalendarViewDayCellHeight + CalendarViewDayCellOffset);
		}
	}
}

- (void)generateMonthRects
{
    [monthRects removeAllObjects];
    
    NSDateFormatter *formater = [NSDateFormatter new];
    NSArray *monthNames = [formater standaloneMonthSymbols];
    NSInteger index = 0;
    CGFloat x, y = CalendarViewMonthTitleOffsetY;
    NSInteger xi = 0;
    for (NSString *monthName in monthNames) {
        x = xi * CalendarViewMonthCellWidth;
        ++xi;
        ++index;
        
        CalendarViewRect *monthRect = [[CalendarViewRect alloc] init];
        monthRect.value = index;
        monthRect.str = monthName;
        monthRect.frame = CGRectMake(x, y, CalendarViewMonthCellWidth, CalendarViewMonthCellHeight);
        [monthRects addObject:monthRect];
        
        if (xi >= CalendarViewMonthInLine) {
            xi = 0;
            y += CalendarViewMonthYStep;
        }
    }
}

- (void)generateYearRects
{
    [yearRects removeAllObjects];
    
    NSMutableArray *years = [[NSMutableArray alloc] init];
    for (NSInteger year = currentYear - CalendarViewYearsAround; year <= currentYear + CalendarViewYearsAround; ++year) {
        [years addObject:@(year)];
    }
    
    CGFloat x, y = CalendarViewYearTitleOffsetY;
    NSInteger xi = 0;
    for (NSNumber *obj in years) {
        x = xi * CalendarViewYearCellWidth;
        ++xi;
        
        CalendarViewRect *yearRect = [[CalendarViewRect alloc] init];
        yearRect.value = [obj integerValue];
        yearRect.str = [NSString stringWithFormat:@"%ld", (long)[obj integerValue]];
        yearRect.frame = CGRectMake(x, y, CalendarViewYearCellWidth, CalendarViewYearCellHeight);
        [yearRects addObject:yearRect];
        
        if (xi >= CalendarViewYearsInLine) {
            xi = 0;
            y += CalendarViewYearYStep;
        }
    }
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextClearRect(context, rect);
	
	CGContextSetFillColorWithColor(context, bgColor.CGColor);
	CGContextFillRect(context, rect);
    
    UIColor * fontColor = self.fontColor != [UIColor clearColor] ? self.fontColor : bgColor;
    
	NSDictionary *attributesBlack = [self generateAttributes:CalendarViewDefaultFont
												withFontSize:CalendarViewDayFontSize
												   withColor:fontColor
											   withAlignment:NSTextAlignmentFromCTTextAlignment(kCTCenterTextAlignment)];
	
	NSDictionary *attributesWhite = [self generateAttributes:CalendarViewDefaultFont
												withFontSize:CalendarViewDayFontSize
                                                   withColor:self.fontSelectedColor
											   withAlignment:NSTextAlignmentFromCTTextAlignment(kCTCenterTextAlignment)];
    
	NSDictionary *attributesRedRight = [self generateAttributes:CalendarViewDefaultFont
												   withFontSize:CalendarViewHeaderFontSize
													  withColor:self.fontHeaderColor
												  withAlignment:NSTextAlignmentFromCTTextAlignment(kCTRightTextAlignment)];
	
	NSDictionary *attributesRedLeft = [self generateAttributes:CalendarViewDefaultFont
												  withFontSize:CalendarViewHeaderFontSize
													 withColor:self.fontHeaderColor
												 withAlignment:NSTextAlignmentFromCTTextAlignment(kCTLeftTextAlignment)];
    
	CTFontRef cellFont = CTFontCreateWithName((CFStringRef)CalendarViewDefaultFont, CalendarViewDayFontSize, NULL);
	CGRect cellFontBoundingBox = CTFontGetBoundingBox(cellFont);
	CFRelease(cellFont);
    
	NSString *year = [NSString stringWithFormat:@"%ld", (long)currentYear];
	const CGFloat yearNameX = (CalendarViewDayCellWidth - CGRectGetHeight(cellFontBoundingBox)) * 0.5;
    yearTitleRect = CGRectMake(yearNameX, 0, CalendarViewYearLabelWidth, CalendarViewYearLabelHeight);
	[year drawUsingRect:yearTitleRect withAttributes:attributesRedLeft];
	
    if (mode != CM_Years) {
        NSDateFormatter *formater = [NSDateFormatter new];
        NSArray *monthNames = [formater standaloneMonthSymbols];
        NSString *monthName = monthNames[(currentMonth - 1)];
        const CGFloat monthNameX = (CalendarViewDayCellWidth + CalendarViewDayCellOffset) * CalendarViewDaysInWeek - CalendarViewMonthLabelWidth - (CalendarViewDayCellWidth - CGRectGetHeight(cellFontBoundingBox));
        monthTitleRect = CGRectMake(monthNameX, 0, CalendarViewMonthLabelWidth, CalendarViewMonthLabelHeight);
        [monthName drawUsingRect:monthTitleRect withAttributes:attributesRedRight];
    }
	
    NSMutableArray *rects = nil;
    NSInteger currentValue = 0;
    
    switch (type) {
        case CTDay:
        {
            [self drawWeekDays];
            
            rects = dayRects;
            currentValue = currentDay;
        }
        break;
        case CTMonth:
        {
            rects = monthRects;
            currentValue = currentMonth;
        }
        break;
        case CTYear:
        {
            rects = yearRects;
            currentValue = currentYear;
        }
        break;
            
        default:
            break;
    }
    
    if (rects) {
        for (CalendarViewRect *rect in rects) {
            NSDictionary *attrs = nil;
            CGRect rectText = rect.frame;
            rectText.origin.y = rectText.origin.y + ((CGRectGetHeight(rectText) - CGRectGetHeight(cellFontBoundingBox)) * 0.5);
            
            if (rect.value == currentValue) {
                if (type == CTDay) {
                    [self drawCircle:rect.frame toContext:&context];
                }
                else {
                    [self drawRoundedRectangle:rect.frame toContext:&context];
                }
                
                attrs = attributesWhite;
            }
            else {
                attrs = attributesBlack;
            }
            
            if (self.fontColor == [UIColor clearColor]) {
                CGContextClearRect(context, rect.frame);
                [[CalendarView drawClearText:rect.str rect:rect.frame withAttributes:attrs] drawInRect:rect.frame];

            } else {
                [rect.str drawUsingRect:rectText withAttributes:attrs];
            }

        }
    }
}
+ (UIImage *)drawClearText:(NSString *)text rect:(CGRect)rect withAttributes:(NSDictionary*)attrs {
    
    // draw text image
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 2);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // First fill the background with white.
    //    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    CGContextClearRect(context, rect);
    
    CGContextSetTextDrawingMode(context, kCGTextFill); // This is the default
    [[UIColor blackColor] setFill]; // This is the default
    [text drawInRect:CGRectMake(0, 0, rect.size.width, rect.size.height) withAttributes:attrs];
    
    UIImage * textImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //    UIImage *result = [self revertImage:textImage];
    
    // invert image
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 2);
    context = UIGraphicsGetCurrentContext();
    
    UIColor * bgColor = [attrs valueForKey:NSForegroundColorAttributeName] ?: [UIColor blackColor];
    CGContextSetFillColorWithColor(context, bgColor.CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, rect.size.width, rect.size.height));
    
    CGContextTranslateCTM(context, 0, rect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextClipToMask(context, CGRectMake(0, 0, textImage.size.width, textImage.size.height), textImage.CGImage);
    
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    [textImage drawInRect:CGRectMake(0, 0, rect.size.width, rect.size.height) blendMode:kCGBlendModeCopy alpha:1];
    
    UIImage * result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
}

- (void)drawCircle:(CGRect)rect toContext:(CGContextRef *)context
{
    CGContextSetFillColorWithColor(*context, self.selectionColor.CGColor);
    CGContextFillEllipseInRect(*context, rect);
}

- (void)drawRoundedRectangle:(CGRect)rect toContext:(CGContextRef *)context
{
    CGContextSetFillColorWithColor(*context, self.selectionColor.CGColor);
    
    CGFloat minx = CGRectGetMinX(rect), midx = CGRectGetMidX(rect), maxx = CGRectGetMaxX(rect);
    CGFloat miny = CGRectGetMinY(rect), midy = CGRectGetMidY(rect), maxy = CGRectGetMaxY(rect);
    
    CGContextMoveToPoint(*context, minx, midy);
    CGContextAddArcToPoint(*context, minx, miny, midx, miny, CalendarViewSelectionRound);
    CGContextAddArcToPoint(*context, maxx, miny, maxx, midy, CalendarViewSelectionRound);
    CGContextAddArcToPoint(*context, maxx, maxy, midx, maxy, CalendarViewSelectionRound);
    CGContextAddArcToPoint(*context, minx, maxy, minx, midy, CalendarViewSelectionRound);
    CGContextClosePath(*context);
    
    CGContextSetStrokeColorWithColor(*context, self.selectionColor.CGColor);
    CGContextDrawPath(*context, kCGPathFillStroke);
}

- (void)drawWeekDays
{
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	NSArray *weekdayNames = [dateFormatter shortWeekdaySymbols];
	
	NSDictionary *attrs = [self generateAttributes:CalendarViewDefaultFont
									  withFontSize:CalendarViewDayFontSize
										 withColor:self.fontColor
									 withAlignment:NSTextAlignmentFromCTTextAlignment(kCTCenterTextAlignment)];
	
	CGFloat x = 0;
	CGFloat y = CalendarViewWeekDaysYOffset;
	const CGFloat w = CalendarViewDayCellWidth;
	const CGFloat h = CalendarViewDayCellHeight;
    
	for (int i = 1; i < CalendarViewDaysInWeek; ++i) {
		x = (i - 1) * (CalendarViewDayCellWidth + CalendarViewDayCellOffset);
		NSString *str = [NSString stringWithFormat:@"%@", weekdayNames[i]];
		[str drawUsingRect:CGRectMake(x, y, w, h) withAttributes:attrs];
	}
	
	NSString *strSunday = [NSString stringWithFormat:@"%@",weekdayNames[0]];
	x = (CalendarViewDaysInWeek - 1) * (CalendarViewDayCellWidth + CalendarViewDayCellOffset);
	[strSunday drawUsingRect:CGRectMake(x, y, w, h) withAttributes:attrs];
}

- (UIImage *) imageWithView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}
#pragma mark - Change date event

- (void)changeDateEvent
{
	NSDate *currentDate = [self currentDate];
	if (_calendarDelegate && [_calendarDelegate respondsToSelector:@selector(didChangeCalendarDate:)]) {
		[_calendarDelegate didChangeCalendarDate:currentDate];
	}
    if (_calendarDelegate && [_calendarDelegate respondsToSelector:@selector(didChangeCalendarDate:withType:withEvent:)]) {
        [_calendarDelegate didChangeCalendarDate:currentDate withType:type withEvent:event];
    }
}

#pragma mark - Gestures

- (void)leftSwipe:(UISwipeGestureRecognizer *)recognizer
{
    event = CE_SwipeLeft;
    
    switch (type) {
        case CTDay:
        {
            if (currentMonth == CalendarViewMonthInYear) {
                currentMonth = 1;
                ++currentYear;
            }
            else {
                ++currentMonth;
            }
            
            [self generateDayRects];
        }
        break;
        case CTMonth:
        {
            ++currentYear;
        }
        break;
        case CTYear:
        {
            currentYear += CalendarViewYearsAround;
            [self generateYearRects];
        }
        break;
            
        default:
            break;
    }
	
	[self changeDateEvent];
	[self fade];
}

- (void)rightSwipe:(UISwipeGestureRecognizer *)recognizer
{
    event = CE_SwipeRight;
    
    switch (type) {
        case CTDay:
        {
            if (currentMonth == 1) {
                currentMonth = CalendarViewMonthInYear;
                --currentYear;
            }
            else {
                --currentMonth;
            }
            
            [self generateDayRects];
        }
        break;
        case CTMonth:
        {
            --currentYear;
        }
        break;
        case CTYear:
        {
            currentYear -= CalendarViewYearsAround;
            [self generateYearRects];
        }
        break;
            
        default:
            break;
    }
    
	[self changeDateEvent];
	[self fade];
}

- (void)pinch:(UIPinchGestureRecognizer *)recognizer
{
    const NSInteger oldType = type;
    
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        NSInteger t = type;
        if (recognizer.velocity > 0) {
            event = CE_PinchIn;
            if (t - 1 >= minType) {
                --t;
            }
        }
        else {
            event = CE_PinchOut;
            if (t + 1 < CT_Count) {
                ++t;
            }
        }
        
        if (t != type) {
            type = t;
            
            if (type > oldType) {   [self fadeOut];
            } else              {   [self fadeIn];  }
        }
    }
}

- (void)tap:(UITapGestureRecognizer *)recognizer
{
    const NSInteger oldType = type;
    event = CE_Tap;
    CGPoint touchPoint = [recognizer locationInView:self];

    if (CGRectContainsPoint(yearTitleRect, touchPoint)) {
        if (type != CTYear) {
            
            if (maxType < CTYear) {
                goto selectMonth;
                
            } else {
                type = CTYear;
                [self fadeOut];
            }
        }
        return;
    }
    
    if (CGRectContainsPoint(monthTitleRect, touchPoint)) {
    selectMonth:
        NSLog(@"Tap maX %ld select %ld", maxType, CTMonth);
        if (type != CTMonth && maxType >= CTMonth) {
            type = CTMonth;
            
            if (type > oldType) {   [self fadeOut];
            } else              {   [self fadeIn];  }
        }
        return;
    }

    BOOL hasEvent = NO;
    switch (type) {
        case CTDay:
        {
            hasEvent = [self checkPoint:touchPoint inArray:dayRects andSetValue:&currentDay];
        }
        break;
        case CTMonth:
        {
            hasEvent = [self checkPoint:touchPoint inArray:monthRects andSetValue:&currentMonth];
        }
        break;
        case CTYear:
        {
            hasEvent = [self checkPoint:touchPoint inArray:yearRects andSetValue:&currentYear];
        }
        break;
            
        default:
            break;
    }
    
    if (hasEvent) {
        [self changeDateEvent];
        [self setNeedsDisplay];
        [self performSelector:@selector(doubleTap:) withObject:nil afterDelay:0.01];
//        [self doubleTap:nil];
    }
}

- (void)doubleTap:(UITapGestureRecognizer *)recognizer
{
    const NSInteger oldType = type;

    event = CE_DoubleTap;
    if (type != CTDay && type > minType) {
        --type;
        
        if (type > oldType) {   [self fadeOut];
        } else              {   [self fadeIn];  }
    }
    
    if (type == CTDay && recognizer) {
        [self generateDayRects];
    }
    
    NSDate *currentDate = [self currentDate];
    if (event == CE_DoubleTap && _calendarDelegate && [_calendarDelegate respondsToSelector:@selector(didDoubleTapCalendar:withType:)] && recognizer) {
        [_calendarDelegate didDoubleTapCalendar:currentDate withType:type];
    }
}

#pragma mark - Additional functions

- (BOOL)checkPoint:(CGPoint)point inArray:(NSMutableArray *)array andSetValue:(NSInteger *)value
{
    for (CalendarViewRect *rect in array) {
        if (CGRectContainsPoint(rect.frame, point)) {
            *value = rect.value;
            return YES;
        }
    }
    return NO;
}

- (NSDictionary *)generateAttributes:(NSString *)fontName withFontSize:(CGFloat)fontSize withColor:(UIColor *)color withAlignment:(NSTextAlignment)textAlignment
{
	NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[paragraphStyle setAlignment:textAlignment];
	[paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
	
	NSDictionary * attrs = @{
							 NSFontAttributeName : [UIFont fontWithName:fontName size:fontSize],
							 NSForegroundColorAttributeName : color,
							 NSParagraphStyleAttributeName : paragraphStyle
							 };
	
	return attrs;
}

- (void)fade
{
	[UIView animateWithDuration:CalendarViewSwipeMonthFadeInTime
						  delay:0
						options:0
					 animations:^{
						 self.alpha = 0.0f;
					 }
					 completion:^(BOOL finished) {
						 [self setNeedsDisplay];
						 [UIView animateWithDuration:CalendarViewSwipeMonthFadeOutTime
											   delay:0
											 options:0
										  animations:^{
											  self.alpha = 1.0f;
										  }
										  completion:nil];
					 }];
}

- (void)fadeOut
{
//    static CGRect defaultRect; if (!defaultRect.size.width) {defaultRect = self.frame; }
    long month = [self currentDate].month;
    long year = [self currentDate].year;
    
    CalendarViewRect * viewRect;
    if (type == CTMonth) {
        viewRect = [monthRects objectAtIndex:month-1];
    } else if (type == CTYear) {
        for (CalendarViewRect *r in yearRects) {
            if (r.value == year) {
                viewRect = r;
                break;
            }
        }
    }
    
    const CGRect rect = viewRect.frame;
    CGFloat scale = rect.size.height/self.frame.size.height;

    const CGFloat offsetX = rect.origin.x + rect.size.width/2 - self.bounds.size.width/2;
    const CGFloat offsetY = rect.origin.y + rect.size.height/2 - self.bounds.size.height/2;
    
//    NSLog(@"Fade Out c %@ c %@ x %f y %f ", NSStringFromCGPoint(self.center), NSStringFromCGPoint(CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect))), offsetX, offsetY);
    
    // get screenshot with blur effect
    UIGraphicsBeginImageContext(self.bounds.size);
    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:YES];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImageView * imageView = [[UIImageView alloc] initWithImage:img];
    [self addSubview:imageView];
    // refresh display
    [self setNeedsDisplay];

    [UIView animateWithDuration:CalendarViewSwipeMonthFadeInTime + .2
                          delay:0
                        options:0
                     animations:^{

                         CGAffineTransform scaleTrans  = CGAffineTransformMakeScale(scale, scale);
                         CGAffineTransform lefttorightTrans  = CGAffineTransformMakeTranslation(offsetX,offsetY);
                         imageView.transform = CGAffineTransformConcat(scaleTrans, lefttorightTrans);
                         imageView.alpha = .3;
                         
                     }
                     completion:^(BOOL finished) {
                         [imageView removeFromSuperview];
                     }];
}
//- (UIImage*)imageByCropping:(CGRect)rect
//{
//    //create a context to do our clipping in
//    UIGraphicsBeginImageContext(rect.size);
//    CGContextRef currentContext = UIGraphicsGetCurrentContext();
//    
//    //create a rect with the size we want to crop the image to
//    //the X and Y here are zero so we start at the beginning of our
//    //newly created context
//    CGRect clippedRect = CGRectMake(0, 0, rect.size.width, rect.size.height);
//    CGContextClipToRect( currentContext, clippedRect);
//    
//    //create a rect equivalent to the full size of the image
//    //offset the rect by the X and Y we want to start the crop
//    //from in order to cut off anything before them
//    CGRect drawRect = CGRectMake(rect.origin.x * -1,
//                                 rect.origin.y * -1,
//                                 self.size.width,
//                                 self.size.height);
//    
//    //draw the image to our clipped context using our offset rect
//    CGContextDrawImage(currentContext, drawRect, self.CGImage);
//    
//    //pull the image from our cropped context
//    UIImage *cropped = UIGraphicsGetImageFromCurrentImageContext();
//    
//    //pop the context to get back to the default
//    UIGraphicsEndImageContext();
//    
//    //Note: this is autoreleased
//    return cropped;
//}

- (void)fadeIn
{
    UIView * calendar = self.superview.superview;
    CGSize size = CGSizeMake(calendar.bounds.size.width*2, calendar.bounds.size.height*2);
    UIGraphicsBeginImageContextWithOptions(size, YES, 0.0);
    [calendar drawViewHierarchyInRect:calendar.bounds afterScreenUpdates:YES];
    UIImage *screenShot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
//    CGRect clippedRect  = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.bounds.size.width, self.bounds.size.height);
    CGRect clippedRect  = CGRectMake(self.frame.origin.x*2, 40.0*2, self.bounds.size.width*2, self.bounds.size.height*2);
    CGImageRef imageRef = CGImageCreateWithImageInRect(screenShot.CGImage, clippedRect);
    UIImage *cutImage   = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    // draw cut image
//    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0);
//    [cutImage drawInRect:self.bounds];
//    UIImage * drawImg = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
    
    UIImageView * oldView = [[UIImageView alloc] initWithImage:cutImage];
    oldView.frame = CGRectMake(0, -2, self.bounds.size.width, self.bounds.size.height);
    
    NSLog(@"SCREEN SHOT %@ CUT IMAGE %@ clipRect %@ selfRect %@", NSStringFromCGSize(screenShot.size), NSStringFromCGSize(cutImage.size), NSStringFromCGRect(clippedRect), NSStringFromCGRect(self.frame));
    
    long month = [self currentDate].month;
    long year = [self currentDate].year;

    [self generateDayRects];
    [self setNeedsDisplay];
    
    [self addSubview:oldView];


    CalendarViewRect * viewRect;
    if (type == CTDay) {
        viewRect = [monthRects objectAtIndex:month-1];
    } else if (type == CTMonth) {
        for (CalendarViewRect *r in yearRects) {
            if (r.value == year) {
                viewRect = r;
                break;
            }
        }
    }
//    NSLog(@"viewRect %@ sting %@ type %d", NSStringFromCGRect(viewRect.frame), viewRect.str, (int)type);

    CGRect rect = viewRect.frame;
    const CGFloat offsetX = rect.origin.x + rect.size.width/2 - self.bounds.size.width/2;
    const CGFloat offsetY = rect.origin.y + rect.size.height/2 - self.bounds.size.height/2;

    
    bgColor = [self getPixelColorAtLocation:CGPointMake(200, 150) image:cutImage];
    // get new image
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0);
    [self drawRect:self.bounds];
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    // get new image end
    bgColor = [UIColor clearColor];

    UIImageView * newView = [[UIImageView alloc] initWithImage:img];
    [self addSubview:newView];

    CGAffineTransform scaleTrans  = CGAffineTransformMakeScale(0.2f, 0.1f);
    CGAffineTransform lefttorightTrans  = CGAffineTransformMakeTranslation(offsetX,offsetY);
    newView.transform = CGAffineTransformConcat(scaleTrans, lefttorightTrans);
    newView.alpha = .3;

    [UIView animateWithDuration:CalendarViewSwipeMonthFadeInTime + .2
                          delay:0
                        options:0
                     animations:^{
                         
//                         CGFloat scale = 10*self.frame.size.height/rect.size.height;
//                         CGAffineTransform scaleTrans  = CGAffineTransformMakeScale(scale, scale);
//                         CGAffineTransform lefttorightTrans  = CGAffineTransformMakeTranslation(-offsetX*scale,-offsetY*scale);
//                         oldView.transform = CGAffineTransformConcat(scaleTrans, lefttorightTrans);
//                         oldView.alpha = .2;

                         newView.transform = CGAffineTransformIdentity;
                         newView.alpha = 1.0;

                     }
                     completion:^(BOOL finished) {
                         
            
                         [oldView removeFromSuperview];
                         [newView removeFromSuperview];
                     }];
}

- (CGContextRef) createARGBBitmapContextFromImage:(CGImageRef)inImage
{
    CGContextRef    context = NULL;
    CGColorSpaceRef colorSpace;
    void *          bitmapData;
    int             bitmapByteCount;
    int             bitmapBytesPerRow;
    
    // Get image width, height. We'll use the entire image.
    size_t pixelsWide = CGImageGetWidth(inImage);
    size_t pixelsHigh = CGImageGetHeight(inImage);
    
    // Declare the number of bytes per row. Each pixel in the bitmap in this
    // example is represented by 4 bytes; 8 bits each of red, green, blue, and
    // alpha.
    bitmapBytesPerRow   = (int)(pixelsWide * 4);
    bitmapByteCount     = (int)(bitmapBytesPerRow * pixelsHigh);
    
    // Use the generic RGB color space.
    colorSpace = CGColorSpaceCreateDeviceRGB();
    
    if (colorSpace == NULL)
    {
        fprintf(stderr, "Error allocating color space\n");
        return NULL;
    }
    
    // Allocate memory for image data. This is the destination in memory
    // where any drawing to the bitmap context will be rendered.
    bitmapData = malloc( bitmapByteCount );
    if (bitmapData == NULL)
    {
        fprintf (stderr, "Memory not allocated!");
        CGColorSpaceRelease( colorSpace );
        return NULL;
    }
    
    // Create the bitmap context. We want pre-multiplied ARGB, 8-bits
    // per component. Regardless of what the source image format is
    // (CMYK, Grayscale, and so on) it will be converted over to the format
    // specified here by CGBitmapContextCreate.
    context = CGBitmapContextCreate (bitmapData,
                                     pixelsWide,
                                     pixelsHigh,
                                     8,      // bits per component
                                     bitmapBytesPerRow,
                                     colorSpace,
                                     (CGBitmapInfo)kCGImageAlphaPremultipliedFirst);
    if (context == NULL)
    {
        free (bitmapData);
        fprintf (stderr, "Context not created!");
    }
    
    // Make sure and release colorspace before returning
    CGColorSpaceRelease( colorSpace );
    
    return context;
}
- (UIColor *) pixelColorForImage:(UIImage *)image point:(CGPoint)point {
    CFDataRef pixelData = CGDataProviderCopyData(CGImageGetDataProvider(image.CGImage));
    const UInt8* data = CFDataGetBytePtr(pixelData);

    int pixelInfo = ((image.size.width* point.y) + point.x) * 4; // The image is png

    UInt8 red = data[pixelInfo];         // If you need this info, enable it
    UInt8 green = data[(pixelInfo + 1)]; // If you need this info, enable it
    UInt8 blue = data[pixelInfo + 2];    // If you need this info, enable it
    
    return [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:1];
}

- (UIColor*) getPixelColorAtLocation:(CGPoint)point image:(UIImage *)image
{
    
    UIColor* color = nil;
    
    CGImageRef inImage;
    
    inImage = image.CGImage;
    CGFloat alpha = 1;
    
    // Create off screen bitmap context to draw the image into. Format ARGB is 4 bytes for each pixel: Alpa, Red, Green, Blue
    CGContextRef cgctx = [self createARGBBitmapContextFromImage:inImage];
    if (cgctx == NULL) { return nil; /* error */ }
    
    size_t w = CGImageGetWidth(inImage);
    size_t h = CGImageGetHeight(inImage);
    CGRect rect = {{0,0},{w,h}};
    
    
    // Draw the image to the bitmap context. Once we draw, the memory
    // allocated for the context for rendering will then contain the
    // raw image data in the specified color space.
    CGContextDrawImage(cgctx, rect, inImage);
    
    // Now we can get a pointer to the image data associated with the bitmap
    // context.
    unsigned char* data = CGBitmapContextGetData (cgctx);
    if (data != NULL) {
        //offset locates the pixel in the data from x,y.
        //4 for 4 bytes of data per pixel, w is width of one row of data.
        int offset = 4*((w*round(point.y))+round(point.x));
        alpha =  data[offset];
        int red = data[offset+1];
        int green = data[offset+2];
        int blue = data[offset+3];
        color = [UIColor colorWithRed:(red/255.0f) green:(green/255.0f) blue:(blue/255.0f) alpha:(alpha/255.0f)];
    }
    
    // When finished, release the context
    //CGContextRelease(cgctx);
    // Free image data memory for the context
    if (data) { free(data); }
    
    return color;
}
@end
