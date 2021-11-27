/*
 * identify.library
 *
 * Copyright (C) 2021 Richard "Shred" Koerber
 *        http://identify.shredzone.org
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#pragma libcall IdentifyBase IdExpansion 1e 801
#pragma libcall IdentifyBase IdHardware 24 8002
#pragma libcall IdentifyBase IdAlert 2a 8002
#pragma libcall IdentifyBase IdFunction 30 90803
#pragma libcall IdentifyBase IdHardwareNum 36 8002
#pragma libcall IdentifyBase IdHardwareUpdate 3c 00
#pragma libcall IdentifyBase IdFormatString 42 A09804
#pragma libcall IdentifyBase IdEstimateFormatSize 48 9802
#pragma tagcall IdentifyBase IdAlertTags 2a 8002
#pragma tagcall IdentifyBase IdExpansionTags 1e 801
#pragma tagcall IdentifyBase IdFunctionTags 30 90803
#pragma tagcall IdentifyBase IdHardwareTags 24 8002
#pragma tagcall IdentifyBase IdHardwareNumTags 24 8002
#pragma tagcall IdentifyBase IdFormatString 42 A09804
#pragma tagcall IdentifyBase IdEstimateFormatSize 48 9802
