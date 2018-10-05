/*
 * Copyright (C) 2018 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {buildReducer, updateIn} from '../ReducerHelpers'
import {
  SET_PUBLISH_GRADES_STATUS,
  SET_UNMUTE_ASSIGNMENT_STATUS,
  UPDATE_ASSIGNMENT
} from './AssignmentActions'

const handlers = {}

handlers[SET_PUBLISH_GRADES_STATUS] = (state, {payload}) =>
  updateIn(state, 'assignment', {publishGradesStatus: payload.status})

handlers[SET_UNMUTE_ASSIGNMENT_STATUS] = (state, {payload}) =>
  updateIn(state, 'assignment', {unmuteAssignmentStatus: payload.status})

handlers[UPDATE_ASSIGNMENT] = (state, {payload}) =>
  updateIn(state, 'assignment', {
    assignment: {...state.assignment.assignment, ...payload.assignment}
  })

export default function buildAssignmentReducer(env) {
  return buildReducer(handlers, {
    assignment: {
      assignment: env.assignment,
      publishGradesStatus: null,
      unmuteAssignmentStatus: null
    }
  })
}
