/**********************************************************************************
 *                                                                           
 *  The MIT License (MIT)
 *  Copyright (c) 2015 Lemberg Solutions Limited
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to
 *  deal in the Software without restriction, including without limitation the 
 *  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 *  sell copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *   The above copyright notice and this permission notice shall be included in
 *   all  copies or substantial portions of the Software.
 *
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *  FROM,  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS 
 *  IN THE SOFTWARE.
 *
 *                                                                           
 *****************************************************************************/



#import "DCMainProxy+Additions.h"
#import "DCEvent+DC.h"
#import "DCMainEvent+DC.h"
#import "DCBof.h"
#import "DCTimeRange+DC.h"
#import "DCLevel.h"
#import "DCTrack.h"

#import "NSDate+DC.h"
#import "NSArray+DC.h"

@implementation DCMainProxy (Additions)

#pragma mark -

- (NSArray*)daysForClass:(Class)eventClass {
  return [self daysForClass:eventClass predicate:nil];
}

- (NSArray*)daysForClass:(Class)eventClass predicate:(NSPredicate*)aPredicate {
  @try {
    NSEntityDescription* entityDescription =
        [NSEntityDescription entityForName:NSStringFromClass(eventClass)
                    inManagedObjectContext:self.workContext];
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entityDescription];
    [fetchRequest setReturnsObjectsAsFaults:NO];
    [fetchRequest setPropertiesToFetch:@[ @"date" ]];
    [fetchRequest setResultType:NSDictionaryResultType];
    [fetchRequest setReturnsDistinctResults:YES];

    [fetchRequest setPredicate:aPredicate];
    NSArray* result =
        [self.workContext executeFetchRequest:fetchRequest error:nil];
    if (result && [result count]) {
      return [[result objectsFromDictionaries] sortedDates];
    }
  } @catch (NSException* exception) {
    NSLog(@"%@", NSStringFromClass([self class]));
    NSLog(@"%@", [self.workContext description]);
    NSLog(@"%@", [self.workContext.persistentStoreCoordinator description]);
    NSLog(@"%@", [self.workContext.persistentStoreCoordinator
                         .managedObjectModel description]);
    NSLog(@"%@", [self.workContext.persistentStoreCoordinator.managedObjectModel
                         .entities description]);
    @throw exception;
  } @finally {
  }
  return nil;
}

- (NSArray*)eventsForDay:(NSDate*)day
                forClass:(__unsafe_unretained Class)eventClass {
  return [self eventsForDay:day forClass:eventClass predicate:nil];
}

- (NSArray*)eventsForDay:(NSDate*)day
                forClass:(__unsafe_unretained Class)eventClass
               predicate:(NSPredicate*)aPredicate {
  @try {
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription* entity =
        [NSEntityDescription entityForName:NSStringFromClass(eventClass)
                    inManagedObjectContext:self.workContext];
    [fetchRequest setEntity:entity];

    NSPredicate* datePredicate =
        [NSPredicate predicateWithFormat:@"date = %@", day];
    NSPredicate* mergedPredicate =
        aPredicate
            ? [NSCompoundPredicate
                  andPredicateWithSubpredicates:@[ datePredicate, aPredicate ]]
            : datePredicate;

    [fetchRequest setPredicate:mergedPredicate];

    NSError* error = nil;
    NSArray* fetchedObjects =
        [self.workContext executeFetchRequest:fetchRequest error:&error];
    if (error || !fetchedObjects) {
      NSLog(@"WRONG! program events fetch: %@", error);
    }
    return fetchedObjects;
  } @catch (NSException* exception) {
    NSLog(@"%@", NSStringFromClass([self class]));
    NSLog(@"%@", [self.workContext description]);
    NSLog(@"%@", [self.workContext.persistentStoreCoordinator description]);
    NSLog(@"%@", [self.workContext.persistentStoreCoordinator
                         .managedObjectModel description]);
    NSLog(@"%@", [self.workContext.persistentStoreCoordinator.managedObjectModel
                         .entities description]);
    @throw exception;
  } @finally {
  }
  return nil;
}

- (NSArray*)uniqueTimeRangesForDay:(NSDate*)day
                          forClass:(__unsafe_unretained Class)eventClass {
  return [self uniqueTimeRangesForDay:day forClass:eventClass predicate:nil];
}

- (NSArray*)uniqueTimeRangesForDay:(NSDate*)day
                          forClass:(__unsafe_unretained Class)eventClass
                         predicate:(NSPredicate*)aPredicate {
  @try {
    NSEntityDescription* entityDescription =
        [NSEntityDescription entityForName:NSStringFromClass(eventClass)
                    inManagedObjectContext:self.workContext];
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entityDescription];
    [fetchRequest setReturnsObjectsAsFaults:NO];

    NSPredicate* datePredicate =
        [NSPredicate predicateWithFormat:@"date = %@", day];
    NSPredicate* mergedPredicate =
        aPredicate
            ? [NSCompoundPredicate
                  andPredicateWithSubpredicates:@[ datePredicate, aPredicate ]]
            : datePredicate;
    [fetchRequest setPredicate:mergedPredicate];

    NSArray* result =
        [self.workContext executeFetchRequest:fetchRequest error:nil];
    if (result && [result count]) {
      return
          [[self DC_filterUniqueTimeRangeFromEvents:result] sortedByStartHour];
    }
  } @catch (NSException* exception) {
    NSLog(@"%@", NSStringFromClass([self class]));
    NSLog(@"%@", [self.workContext description]);
    NSLog(@"%@", [self.workContext.persistentStoreCoordinator description]);
    NSLog(@"%@", [self.workContext.persistentStoreCoordinator
                         .managedObjectModel description]);
    NSLog(@"%@", [self.workContext.persistentStoreCoordinator.managedObjectModel
                         .entities description]);
    @throw exception;
  } @finally {
  }
  return nil;
}

- (NSArray*)favoriteEvents {
  return [self favoriteEventsWithPredicate:nil];
}

- (NSArray*)favoriteEventsWithPredicate:(NSPredicate*)aPredicate {
  @try {
    NSEntityDescription* entityDescription =
        [NSEntityDescription entityForName:NSStringFromClass([DCEvent class])
                    inManagedObjectContext:self.workContext];
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entityDescription];
    [fetchRequest setReturnsObjectsAsFaults:NO];
    NSPredicate* predicate = [NSPredicate
        predicateWithFormat:@"favorite=%@", [NSNumber numberWithBool:YES]];
    [fetchRequest setPredicate:predicate];

    NSArray* result =
        [self.workContext executeFetchRequest:fetchRequest error:nil];
    NSArray* uniqueDates =
        [result valueForKeyPath:@"@distinctUnionOfObjects.date"];
    NSArray* sortDates = [uniqueDates sortedDates];
    NSMutableArray* eventsByDate = [NSMutableArray array];
    for (id date in sortDates) {
      NSPredicate* predicate =
          [NSPredicate predicateWithFormat:@"date == %@", date];
      NSArray* eventsForOneDay = [result filteredArrayUsingPredicate:predicate];
      NSArray* uniqueSection = [[self DC_filterUniqueTimeRangeFromEvents:
                                          eventsForOneDay] sortedByStartHour];
      NSDictionary* dayInfo = @{
        @"sections" : [NSMutableArray arrayWithArray:uniqueSection],
        @"events" : [NSMutableArray arrayWithArray:eventsForOneDay]
      };
      [eventsByDate addObject:dayInfo];
    }

    if (eventsByDate && [eventsByDate count]) {
      return eventsByDate;
    }
  } @catch (NSException* exception) {
    NSLog(@"%@", NSStringFromClass([self class]));
    NSLog(@"%@", [self.workContext description]);
    NSLog(@"%@", [self.workContext.persistentStoreCoordinator description]);
    NSLog(@"%@", [self.workContext.persistentStoreCoordinator
                         .managedObjectModel description]);
    NSLog(@"%@", [self.workContext.persistentStoreCoordinator.managedObjectModel
                         .entities description]);
    @throw exception;
  } @finally {
  }

  return nil;
}

- (BOOL)isFilterCleared {
  NSArray* levels =
      [self getAllInstancesOfClass:[DCLevel class] inMainQueue:YES];
  NSArray* tracks =
      [self getAllInstancesOfClass:[DCTrack class] inMainQueue:YES];

  for (DCLevel* level in levels)
    if (![level.selectedInFilter boolValue])
      return NO;

  for (DCTrack* track in tracks)
    if (![track.selectedInFilter boolValue])
      return NO;

  return YES;
}

#pragma mark -

- (NSArray*)DC_filterUniqueTimeRangeFromEvents:(NSArray*)events {
  NSMutableArray* ranges =
      [[NSMutableArray alloc] initWithCapacity:events.count];
  for (DCMainEvent* event in events) {
    BOOL isUnique = YES;
    for (DCTimeRange* range in ranges) {
      if ([event.timeRange isEqualTo:range]) {
        isUnique = NO;
        break;
      }
    }
    if (isUnique) {
      [ranges addObject:event.timeRange];
    }
  }
  return ranges;
}

- (NSString*)DC_firstPartForDateString:(NSString*)string {
  NSArray* components = [string componentsSeparatedByString:@" "];
  if (components.count == 0) {
    NSLog(@"WRONG! date string");
  }
  return components[0];
}

@end
