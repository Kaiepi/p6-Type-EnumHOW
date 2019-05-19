use v6.d;
use nqp;
unit class Type::EnumHOW:auth<github:Kaiepi>:ver<0.0.1> is Metamodel::EnumHOW;

class X::Type::EnumHOW::MissingPackage is Exception {
    method message(--> Str) {
        'Failed to install enum and enum value symbols. Did you forget to call .^set_package?'
    }
}

my subset StashLike where *.WHO ~~ Stash | PseudoStash;

has Hash        %!attributes;
has StashLike:U $!package;

method new(*%named) {
    nqp::create(self).BUILDALL(Empty, %named)
}

method new_type(*%named) {
    my $enum := self.Metamodel::EnumHOW::new_type(|%named);

    # Hack to get around an exception thrown on compose when attempting to pop
    # from @!roles_to_compose.
    my @roles_to_compose = Enumeration;
    given %named<base_type> {
        when Numeric & Stringy { @roles_to_compose.push(NumericStringyEnumeration) }
        when Numeric           { @roles_to_compose.push(NumericEnumeration)        }
        when Stringy           { @roles_to_compose.push(StringyEnumeration)        }
    }
    nqp::bindattr($enum.HOW, Metamodel::EnumHOW, '@!roles_to_compose', @roles_to_compose);

    $enum
}

method package(Mu $enum is raw --> StashLike:U) {
    $!package
}

method set_package(Mu $enum is raw, StashLike:U $package --> StashLike:U) {
    $!package := $package;
}

method add_attribute_with_values(Mu $enum is raw, str $name, %values, Mu:U :$type = Any, Bool :$private = False --> Nil) {
    my $attribute := Attribute.new(:$name, :$type, :package($enum));
    %!attributes{$name} := %values;
    self.Metamodel::EnumHOW::add_attribute($enum, $attribute);

    unless $private {
        my constant AttrType = $type;
        my &accessor := anon method (Enumeration:D: --> AttrType) {
            nqp::getattr(self, self.WHAT, $name)
        };
        my str $accessor-name = nqp::substr($name, 2);
        &accessor.set_name($accessor-name);
        self.add_method($enum, $accessor-name, &accessor);
    }
}

method compose(Mu $enum is raw --> Nil) {
    self.Metamodel::EnumHOW::compose($enum);
    self!install-symbol(self.name($enum), $enum);
}

proto method add_enum_values(Mu $ is raw, $ --> Nil) {*}
multi method add_enum_values(Mu $enum is raw, %values --> Nil) {
    warn 'Adding enum values using a hash will not preserve the order of its pairs. '
       ~ 'Consider adding them using a list of pairs instead if their order must be preserved.';
    callwith $enum, %values.pairs;
}
multi method add_enum_values(Mu $enum is raw, @keys --> Nil) {
    my     @pairs = all(@keys.map(* ~~ Pair)) ?? @keys !! @keys.antipairs;
    my int $idx   = 0;
    for @pairs -> $pair {
        my $key        := $pair.key;
        my $value      := $pair.value;
        my $enum-value := nqp::rebless(nqp::clone($value), $enum);
        nqp::bindattr($enum-value, $enum, '$!key', $key);
        nqp::bindattr($enum-value, $enum, '$!value', $value);
        nqp::bindattr_i($enum-value, $enum, '$!index', $idx);
        for %!attributes.kv -> $attribute, %values {
            nqp::bindattr($enum-value, $enum-value.WHAT, $attribute, %values{$key});
        }
        $idx = nqp::add_i($idx, 1);

        $enum.WHO{$key} := $enum-value;
        self.Metamodel::EnumHOW::add_enum_value($enum, $enum-value);
        self!install-symbol($key, $enum-value);
    }
}

method !install-symbol(str $name, $value is raw --> Nil) {
    nqp::stmts(
      nqp::if(
        nqp::eqaddr(nqp::decont($!package), StashLike),
        (X::Type::EnumHOW::MissingPackage.new.throw)
      ),
      ($!package.WHO{$name} := $value),
      (my $W := nqp::getlexdyn('$*W')),
      nqp::if(
        nqp::defined($W),
        ($W.add_object_if_no_sc($value))
      )
    )
}

=begin pod

=head1 NAME

Type::EnumHOW - Sugar for enum's meta-object protocol

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Enums are not straightforward to create using their meta-object protocol since
a large chunk of the work the runtime does to create enums is handled during
precompilation. Type::EnumHOW extends Metamodel::EnumHOW to provide methods
that both do the work normally done during precompilation and to provide sugar
for customizing enum behaviour without the need to import nqp.

It is recommended to declare enums at compile-time rather than at runtime so
enums and their values can have their serialization context set. This can be
done by either using C<constant> in combination with C<do> or using C<BEGIN>.

Type::EnumHOW extends Metamodel::EnumHOW. Refer to
L<its documentation|https://docs.perl6.org/type/Metamodel::EnumHOW> for more
information.

=head1 METHODS

=item B<^new_type>(I<*%named>)

Creates a new enum type. Named arguments are the same as those taken by
C<Metamodel::EnumHOW.new_type>. If you plan on calling C<^add_enum_values> with
a list of keys, ensure you pass C<:base_type(Int)>.

=item B<^package>()

Returns the package set by C<^set_package>.

=item B<^set_package>(I<$package> where *.WHO ~~ Stash | PseudoStash)

Sets the package in which the enum and its values' symbols will be installed.
This must be called before calling C<^compose> or C<^compose_values>.

=item B<^add_attribute_with_values>(str I<$name>, %values, Mu:U I<:$type> = Any, Bool I<:$private> = False)

Adds an attribute with the name C<$name> to the enum. C<%values> is a hash
of enum value keys to attribute values that is used to bind the attribute
values to their respective enum values when calling C<^compose_values>.
C<$type> is the type of the attribute values. If the attribute should be
private, set C<$private> to C<True>, otherwise a getter will automatically be
added.

=item B<^compose>()

Composes the enum type. Call this after adding enum attributes and methods, but
before adding enum values.

If no package has been set using C<^set_package>, an
C<X::Type::EnumHOW::MissingPackage> exception will be thrown.

=item B<^add_enum_values>(I<%values>)
=item B<^add_enum_values>(I<*@keys>)

Batch adds a list of enum values to an enum and installs them both in the
package set and the enum's package.. C<^compose> must be called before calling
this. Calling this with a hash will warn about the enum values' order not
necessarily being the same as when they were defined in the hash. This may also
be called with either a list of keys or a list of pairs.

If no package has been set using C<^set_package>, an
C<X::Type::EnumHOW::MissingPackage> exception will be thrown.

=head1 AUTHOR

Ben Davies (Kaiepi)

=head1 COPYRIGHT AND LICENSE

Copyright 2019 Ben Davies

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
