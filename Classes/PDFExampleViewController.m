    //
//  PDFExampleViewController.m
//  Leaves
//
//  Created by Tom Brow on 4/19/10.
//  Copyright 2010 Tom Brow. All rights reserved.
//

#import "PDFExampleViewController.h"
#import "Utilities.h"

@implementation PDFExampleViewController

- (id)init {
    if (self = [super init]) {
		CFURLRef pdfURL = CFBundleCopyResourceURL(CFBundleGetMainBundle(), CFSTR("sample.pdf"), NULL, NULL);
		pdf = CGPDFDocumentCreateWithURL((CFURLRef)pdfURL);
		CFRelease(pdfURL);
    }
    return self;
}

- (void)dealloc {
	CGPDFDocumentRelease(pdf);
    [super dealloc];
}


- (void) displayPageNumber:(NSUInteger)pageNumber {
    NSUInteger numberOfPages = CGPDFDocumentGetNumberOfPages(pdf);
    NSString *pageNumberString = [NSString stringWithFormat:@"Page %u of %u", pageNumber, numberOfPages];
    if (leavesView.mode == LeavesViewModeFacingPages) {
        if (pageNumber > numberOfPages) {
            pageNumberString = [NSString stringWithFormat:@"Page %u of %u", pageNumber-1, numberOfPages];
        } else if (pageNumber > 1) {
            pageNumberString = [NSString stringWithFormat:@"Pages %u-%u of %u", pageNumber - 1, pageNumber, numberOfPages];
        }
    }
	self.navigationItem.title = pageNumberString;
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self displayPageNumber:leavesView.currentPageIndex + 1];
}


#pragma mark  LeavesViewDelegate methods

- (void) leavesView:(LeavesView *)leavesView willTurnToPageAtIndex:(NSUInteger)pageIndex {
	[self displayPageNumber:pageIndex + 1];
}


- (void) leavesView:(LeavesView *)theView zoomingCurrentView:(NSUInteger)zoomLevel {
    
    // Remove current Layer 
    // This helps prevent the crash when zooming
    [tiledLayer removeFromSuperlayer];
    
	tiledLayer = [CATiledLayer layer];
    tiledLayer.delegate = self;
    tiledLayer.tileSize = theView.frame.size;
    tiledLayer.levelsOfDetail = 100;
    tiledLayer.levelsOfDetailBias = 200;
    tiledLayer.frame = theView.frame;
	tiledLayer.anchorPoint = CGPointMake(0.5f, 0.5f);
	[theView.layer addSublayer:tiledLayer];
}

- (void) leavesView:(LeavesView *)theView doubleTapCurrentView:(NSUInteger)zoomLevel {	
	[tiledLayer removeFromSuperlayer];
	tiledLayer = nil;
}

#pragma mark LeavesViewDataSource methods

- (NSUInteger) numberOfPagesInLeavesView:(LeavesView*)leavesView {
	return CGPDFDocumentGetNumberOfPages(pdf);
}

- (void) renderPageAtIndex:(NSUInteger)index inContext:(CGContextRef)ctx {
	CGPDFPageRef page = CGPDFDocumentGetPage(pdf, index + 1);
	CGAffineTransform transform = aspectFit(CGPDFPageGetBoxRect(page, kCGPDFMediaBox),
											CGContextGetClipBoundingBox(ctx));
	CGContextConcatCTM(ctx, transform);
	CGContextDrawPDFPage(ctx, page);
}


#pragma mark Layer Support
- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
	if (leavesView.mode == LeavesViewModeSinglePage) {
		CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, 1.0);
		CGContextFillRect(ctx, CGContextGetClipBoundingBox(ctx));
    
		CGContextTranslateCTM(ctx, 0.0, layer.bounds.size.height);
		CGContextScaleCTM(ctx, 1.0, -1.0);
		CGContextConcatCTM(ctx, CGPDFPageGetDrawingTransform(CGPDFDocumentGetPage(pdf, leavesView.currentPageIndex+1), kCGPDFCropBox, layer.bounds, 0, true));
    
		CGContextDrawPDFPage(ctx, CGPDFDocumentGetPage(pdf, leavesView.currentPageIndex+1));	
	} else {
		CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, 1.0);
		CGContextFillRect(ctx, CGContextGetClipBoundingBox(ctx));
		
		CGContextTranslateCTM(ctx, 0.0, layer.bounds.size.height);
		CGContextScaleCTM(ctx, 1.0, -1.0);
		
		// Drawing left page resized
		CGRect leftPage = layer.bounds;
		leftPage.size.width = layer.bounds.size.width / 2;
		CGContextConcatCTM(ctx, CGPDFPageGetDrawingTransform(CGPDFDocumentGetPage(pdf, leavesView.currentPageIndex), kCGPDFCropBox, leftPage, 0, true));
		CGContextDrawPDFPage(ctx, CGPDFDocumentGetPage(pdf, leavesView.currentPageIndex));	

		// Drawing right page resized
		CGRect rightPage = layer.bounds;
		rightPage.size.width = layer.bounds.size.width / 2;
		rightPage.origin.x = layer.bounds.size.width / 2;
		CGContextConcatCTM(ctx, CGPDFPageGetDrawingTransform(CGPDFDocumentGetPage(pdf, leavesView.currentPageIndex+1), kCGPDFCropBox, rightPage, 0, true));
		CGContextDrawPDFPage(ctx, CGPDFDocumentGetPage(pdf, leavesView.currentPageIndex+1));	
		
		
	}

}

#pragma mark Page Moving Commands

-(SEL)nextPage {
	[self goToPage:leavesView.currentPageIndex+1];
	[self displayPageNumber:leavesView.currentPageIndex+1];
}

-(SEL)previousPage {
	[self goToPage:leavesView.currentPageIndex-1];
	[self displayPageNumber:leavesView.currentPageIndex+1];
}


#pragma mark UIViewController

- (void) viewDidLoad {
	[super viewDidLoad];
	leavesView.backgroundRendering = YES;
	[self displayPageNumber:1];

	
	UIBarButtonItem *previousPageButton = [[UIBarButtonItem alloc] initWithTitle:@"<" style:UIBarButtonItemStylePlain target:self action:@selector(previousPage)];
	UIBarButtonItem *nextPageButton = [[UIBarButtonItem alloc] initWithTitle:@">" style:UIBarButtonItemStylePlain target:self action:@selector(nextPage)];
	self.navigationItem.leftBarButtonItem = previousPageButton;
	self.navigationItem.rightBarButtonItem = nextPageButton;
	
	[previousPageButton release];
	[nextPageButton release];

}

@end
