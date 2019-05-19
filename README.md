NAME
====

Type::EnumHOW - Sugar for enum's meta-object protocol

SYNOPSIS
========

    use Type::EnumHOW;

    constant Rank = do {
      my Str @ranks   = 'Unranked', 'Voice', 'Half-Operator', 'Operator', 'Administrator', 'Owner';
      my Str %symbols = %(
          @ranks[0] => ' ',
          @ranks[1] => '+',
          @ranks[2] => '%',
          @ranks[3] => '@',
          @ranks[4] => '&',
          @ranks[5] => '~'
      );

      my constant Rank = Type::EnumHOW.new_type: :name<Rank>, :base_type(Int);
      Rank.^set_package: OUR;
      Rank.^add_attribute_with_values: '$!symbol', %symbols, :type(Str);
      Rank.^compose;
      Rank.^add_enum_values: @ranks;
      Rank.^compose_values;
      Rank
    };

    say Rank::Owner;        # OUTPUT: Owner
    say Rank::Owner.symbol; # OUTPUT: ~

DESCRIPTION
===========

Enums are not straightforward to create using their meta-object protocol since a large chunk of the work the runtime does to create enums is handled during precompilation. Type::EnumHOW extends Metamodel::EnumHOW to provide methods that both do the work normally done during precompilation and to provide sugar for customizing enum behaviour without the need to import nqp.

It is recommended to declare enums at compile-time rather than at runtime so enums and their values can have their serialization context set. This can be done by either using `constant` in combination with `do` or using `BEGIN`.

Type::EnumHOW extends Metamodel::EnumHOW. Refer to [its documentation](https://docs.perl6.org/type/Metamodel::EnumHOW) for more information.

METHODS
=======

  * **^new_type**(**%named*)

Creates a new enum type. Named arguments are the same as those taken by `Metamodel::EnumHOW.new_type`. If you plan on calling `^add_enum_values` with a list of keys, ensure you pass `:base_type(Int)`.

  * **^package**()

Returns the package set by `^set_package`.

  * **^set_package**(*$package* where *.WHO ~~ Stash | PseudoStash)

Sets the package in which the enum and its values' symbols will be installed. This must be called before calling `^compose` or `^compose_values`.

  * **^add_attribute_with_values**(str *$name*, %values, Mu:U *:$type* = Any, Bool *:$private* = False)

Adds an attribute with the name `$name` to the enum. `%values` is a hash of enum value keys to attribute values that is used to bind the attribute values to their respective enum values when calling `^compose_values`. `$type` is the type of the attribute values. If the attribute should be private, set `$private` to `True`, otherwise a getter will automatically be added.

  * **^compose**()

Composes the enum type. Call this after adding enum attributes and methods, but before adding enum values.

If no package has been set using `^set_package`, an `X::Type::EnumHOW::MissingPackage` exception will be thrown.

  * **^add_enum_values**(*%values*)

  * **^add_enum_values**(**@keys*)

Batch adds a list of enum values to an enum and installs them both in the package set and the enum's package.. `^compose` must be called before calling this. Calling this with a hash will warn about the enum values' order not necessarily being the same as when they were defined in the hash. This may also be called with either a list of keys or a list of pairs.

If no package has been set using `^set_package`, an `X::Type::EnumHOW::MissingPackage` exception will be thrown.

AUTHOR
======

Ben Davies (Kaiepi)

COPYRIGHT AND LICENSE
=====================

Copyright 2019 Ben Davies

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

