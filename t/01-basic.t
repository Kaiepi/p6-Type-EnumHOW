use v6.d;
use nqp;
use Test;
use Type::EnumHOW;

plan 12;

{
    my constant Enum = Type::EnumHOW.new_type: :name<Enum>, :base_type(Int);
    throws-like
        { Enum.^compose },
        X::Type::EnumHOW::MissingPackage,
        'throws when composing before a package has been set';
}

{
    my constant Enum = Type::EnumHOW.new_type: :name<Enum>, :base_type(Int);
    Enum.^set_package: MY;
    throws-like
        { Enum.^compose },
        X::Type::EnumHOW::PostCompilationMY,
        'throws when composing after compilation when the package is set to MY';
}

{
    BEGIN {
        my Str          @colours    = 'Red', 'Blue', 'Green';
        my Str          %shortnames = :Red<r>, :Blue<b>, :Green<g>;
        my     constant Colour      = Type::EnumHOW.new_type: :name<Colour>, :base_type(Int);
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
    is Colour::Red.shortname, 'r', 'adds getters for attributes if not specified as private';
    ok nqp::isconcrete(nqp::getobjsc(Colour)), 'adds serialization context for enums when defined at compile-time';
    ok nqp::isconcrete(nqp::getobjsc(Colour::Red)), 'adds serialization context for enum values when defined at compile-time';

    OUR::{$_}:delete for Colour::.keys;
    OUR::<Colour>:delete;
}

{
    BEGIN {
        my Str          @errors = 'Warning', 'Failure', 'Exception', 'Sorrow', 'Panic';
        my     constant Error   = Type::EnumHOW.new_type: :name<Error>, :base_type(Int);
        Error.^set_package: MY;
        Error.^compose;
        Error.^add_enum_values: @errors;
        Error.^compose_values;
    }

    ok MY::<Error>:exists, 'can install enums in MY';
    ok MY::<Warning>:exists, 'can install enum values in MY';
}

# vim: ft=perl6 sw=4 ts=4 sts=4 expandtab
