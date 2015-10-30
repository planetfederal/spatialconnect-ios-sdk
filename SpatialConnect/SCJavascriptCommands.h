/*****************************************************************************
* Licensed to the Apache Software Foundation (ASF) under one
* or more contributor license agreements.  See the NOTICE file
* distributed with this work for additional information
* regarding copyright ownership.  The ASF licenses this file
* to you under the Apache License, Version 2.0 (the
* "License"); you may not use this file except in compliance
* with the License.  You may obtain a copy of the License at
*
*   http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing,
* software distributed under the License is distributed on an
* "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
* KIND, either express or implied.  See the License for the
* specific language governing permissions and limitations
* under the License.
******************************************************************************/

#ifndef SpatialConnect_SCJavascriptCommands_h
#define SpatialConnect_SCJavascriptCommands_h

typedef NS_ENUM(NSInteger, SCJavascriptCommand) {
  DATASERVICE_ACTIVESTORESLIST = 100,
  DATASERVICE_ACTIVESTOREBYID = 101,
  DATASERVICE_SPATIALQUERY = 110,
  DATASERVICE_SPATIALQUERYALL = 111,
  DATASERVICE_GEOSPATIALQUERY = 112,
  DATASERVICE_GEOSPATIALQUERYALL = 113,
  DATASERVICE_CREATEFEATURE = 114,
  DATASERVICE_UPDATEFEATURE = 115,
  DATASERVICE_DELETEFEATURE = 116,
  SENSORSERVICE_GPS = 200
};

typedef NS_ENUM(NSInteger, SCJavascriptError) {
  SCJSERROR_DATASERVICE_ACTIVESTORESLIST = 100,
  SCJSERROR_DATASERVICE_ACTIVESTOREBYID = 101,
  SCJSERROR_DATASERVICE_SPATIALQUERY = 110,
  SCJSERROR_DATASERVICE_SPATIALQUERYALL = 111,
  SCJSERROR_DATASERVICE_GEOSPATIALQUERY = 112,
  SCJSERROR_DATASERVICE_GEOSPATIALQUERYALL = 113,
  SCJSERROR_DATASERVICE_CREATEFEATURE = 114,
  SCJSERROR_DATASERVICE_UPDATEFEATURE = 115,
  SCJSERROR_DATASERVICE_DELETEFEATURE = 116,
  SCJSERROR_SENSORSERVICE_GPS = 200
};

#define SCJS_GEO_CONTAINS @"$geocontains"
#define SCJS_GEO_DISJOINT @"$geodisjoint"
#define SCJS_AND @"$and"
#define SCJS_OR @"$or"
#define SCJS_GREATER_THAN @"$gt"
#define SCJS_GREATER_THAN_EQUAL @"$gte"
#define SCJS_LESS_THAN @"$lt"
#define SCJS_LESS_THAN_EQUAL @"$lte"
#define SCJS_EQUAL @"$e"
#define SCJS_NOT_EQUAL @"$ne"
#define SCJS_BETWEEN @"$between"
#define SCJS_NOT_BETWEEN @"$notbetween"
#define SCJS_IN @"$in"
#define SCJS_NOT_IN @"$notin"
#define SCJS_LIKE @"$like"
#define SCJS_NOT_LIKE @"$notlike"

#endif
