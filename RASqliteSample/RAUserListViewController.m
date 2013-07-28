//
//  RAUserListViewController.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-07-27.
//  Copyright (c) 2013 The Developer Blog. All rights reserved.
//

#import "RAUserListViewController.h"

@interface RAUserListViewController () {
@private
	NSArray *_data;

	RAUserModel *_userModel;
}

@property (nonatomic, readwrite, strong) NSArray *data;

@property (nonatomic, readwrite, strong) RAUserModel *userModel;

@end

@implementation RAUserListViewController

@synthesize data = _data;

@synthesize userModel = _userModel;

- (id)init
{
	if ( self = [super init] ) {
		[self setUserModel:[[RAUserModel alloc] init]];
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	[[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addUser:)] animated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	[self update];
}

- (void)update
{
	[self setData:[[self userModel] getUsers]];
	[[self tableView] reloadData];
}

- (void)addUser:(id)sender
{
	[[self userModel] addUser:@"User"];

	[self update];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [[self data] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSDictionary *user = [[self data] objectAtIndex:[indexPath row]];

	NSString *cellIdentifier = @"cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if ( cell == nil ) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];

		[[cell textLabel] setFont:[UIFont boldSystemFontOfSize:14.0]];
		[[cell textLabel] setTextColor:[UIColor darkGrayColor]];
	}

	NSString *text = [NSString stringWithFormat:@"%@ #%@", [user objectForKey:@"username"], [user objectForKey:@"id"]];
	[[cell textLabel] setText:text];

	return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ( UITableViewCellEditingStyleDelete == editingStyle ) {
		NSDictionary *user = [[self data] objectAtIndex:[indexPath row]];
		[[self userModel] removeUser:[user objectForKey:@"id"]];

		[self update];
	}
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end