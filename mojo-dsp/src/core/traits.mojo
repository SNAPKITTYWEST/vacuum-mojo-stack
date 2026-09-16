# SPDX-License-Identifier: AGPL-3.0-or-later
# mojo-dsp: Core traits

trait Serializable:
    fn serialize(self) -> String
    fn deserialize(cls, data: String) -> Self

trait Hashable:
    fn hash(self) -> String

trait Cloneable:
    fn clone(self) -> Self
