#
# identify.library
#
# Copyright (C) 2021 Frank Wille
#	http://identify.shredzone.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

.set	GetInfo,-592			# powerpc.library _LVOGetInfo+2
.set	PPCINFO_CPUCLOCK,0x80102007
.set	TAG_DONE,0


	.section "PPC-Code","crx"

	.global	_ppc_getinfo
	.long	ppcinfoTags		# pointer to data section

_ppc_getinfo:
# r30 = pointer to _ppc_getinfo
# r31 = PowerPCBase
	mflr	r29			# save LR
	lwz	r28,-4(r30)		# r28 ppcinfoTags
	mr	r3,r31
	mr	r4,r28
	lwz	r0,GetInfo(r3)
	mtlr	r0
	blrl				# GetInfo()
	lwz	r3,4(r28)		# r3: return CPU clock in Hz
	mtlr	r29
	blr				# return to M68k


	.section "PPC-Data","drw"
ppcinfoTags:
	.long	PPCINFO_CPUCLOCK,0
	.long	TAG_DONE
