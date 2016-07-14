//
//  PDVMacros.h
//  PEDev-Console
//
//  Created by Evans, Paul on 2/4/15.
//  Copyright (c) 2015 Paul Evans. All rights reserved.
//

#define PDVLS(key) [[NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"PEDev-Console" ofType:@"bundle"]] localizedStringForKey:(key) value:@"" table:@"Localizable"]
