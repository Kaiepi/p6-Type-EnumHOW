use v6.d;
use nqp;
use Test;
use Type::EnumHOW;

plan 9;

{
    my constant Enum = Type::EnumHOW.new_type: :name<Enum>, :base_type(Int);
    throws-like
        { Enum.^compose },
        X::Type::EnumHOW::MissingPackage,
        'throws when composing before a package has been set';
}

{
    my Str @colours;
    my Str %shortnames;

    BEGIN {
        @colours    = 'Red', 'Blue', 'Green';
        %shortnames = :Red<r>, :Blue<b>, :Green<g>;
        my constant Colour = Type::EnumHOW.new_type: :name<Colour>, :base_type(Int);
        Colour.^set_package: OUR;
        Colour.^add_attribute_with_values: '$!shortname', %shortnames, :type(Str);
        Colour.^compose;
        Colour.^add_enum_values: @colours;
        Colour.^compose_values;
    }

    cmp-ok Colour, '~~', Enumeration, 'enums do the Enumeration role';
    cmp-ok Colour, '~~', NumericEnumeration, 'enums do the NumericEnumeration role if the base type is Numeric';
    ok Colour::<Red>:exists, "adds enum values to the enum's package";
    ok OUR::<Red>:exists, 'adds enum values to the package set';
    ok Colour::Red.^get_attribute_for_usage('$!shortname'), 'adds attributes if specified';
    is Colour::Red.shortname, %shortnames<Red>, 'adds getters for attributes if not specified as private';
    ok nqp::isconcrete(nqp::getobjsc(Colour)), 'adds serialization context for enums when defined at compile-time';
    ok nqp::isconcrete(nqp::getobjsc(Colour::Red)), 'adds serialization context for enum values when defined at compile-time';

    OUR::{$_}:delete for Colour::.keys;
    OUR::<Colour>:delete;
}
