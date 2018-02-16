/*!
 * Copyright 2018 Boundless http://boundlessgeo.com
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License
 */

/*!
 * A list of actions that don't belong in the schema project because they are only relevant
 * to the mobile SDK domain.  If more than one service will send the action, then move it to the
 * schema repo so it can be accessed from com.boundlessgeo.schema.Actions.
 */

extern NSString *const DELETE_SC_DATASTORE;
extern NSString *const DELETE_ALL_SC_DATASTORES;
