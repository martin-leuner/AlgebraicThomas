#############################################################################
##
##  AlgebraicThomas.gi                               AlgebraicThomas package
##
##  Copyright 2013,      Thomas Bächler, RWTH-Aachen University
##                       Mohamed Barakat, University of Kaiserslautern
##
##  Implementation stuff for AlgebraicThomas.
##
#############################################################################

# a new representation for the GAP-category IsScheme

##  <#GAPDoc Label="IsAlgebraicThomasDecompositionOfConstructibleSetRep">
##  <ManSection>
##    <Filt Type="Representation" Arg="M" Name="IsAlgebraicThomasDecompositionOfConstructibleSetRep"/>
##    <Returns>true or false</Returns>
##    <Description>
##      The &GAP; representation of schemes given by an algebraic Thomas decompostion in Maple. <P/>
##      (It is a representation of the &GAP; category <Ref Filt="IsScheme"/>.)
##    </Description>
##  </ManSection>
##  <#/GAPDoc>
##
DeclareRepresentation( "IsAlgebraicThomasDecompositionOfConstructibleSetRep",
        IsSchemeRep,
        [  ] );

####################################
#
# families and types:
#
####################################

##
BindGlobal( "TheTypeAlgebraicThomasDecompositionOfConstructibleSet",
        NewType( TheFamilyOfSchemes,
                IsAlgebraicThomasDecompositionOfConstructibleSetRep ) );

####################################
#
# global variables:
#
####################################

# a central place for configuration variables:

InstallValue( ALGEBRAIC_THOMAS,
        rec(
            
            )
);

##
InstallMethod( HomalgRing,
        "for a constructible set",
        [ IsScheme and IsAlgebraicThomasDecompositionOfConstructibleSetRep ],
        
  function( X )
    
    return X!.ring;
    
end );

##
InstallMethod( Closure,
        "for a constructible set",
        [ IsScheme and IsAlgebraicThomasDecompositionOfConstructibleSetRep ],
        
  function( X )
    local R, I, V;
    
    R := HomalgRing( X );
    
    I := homalgSendBlocking( [  R, "[-1][matrix](map(a->[a],AlgebraicThomas[Ideal](", X!.Thomas_system, ")))" ], HOMALG_IO.Pictograms.Closure );
    
    I := HomalgMatrix( I, R );
    
    SetNrColumns( I, 1 );
    
    V := Spec( R / LeftSubmodule( I ) );
    
    if HasIsAffineSubscheme( X ) and IsAffineSubscheme( X ) then
        SetQuasiAffineSet( V, X );
    fi;
    
    return V;
    
end );

##
InstallMethod( ADefiningIdealOfComplement,
        "for a constructible set",
        [ IsScheme and IsAlgebraicThomasDecompositionOfConstructibleSetRep ],
        
  function( X )
    local CX, I, V, IpJ, J;
    
    CX := Complement( X );
    
    I := DefiningIdeal( HomalgRing( Closure( X ) ) );
    
    V := QuasiAffineSet( I );
    
    IpJ := Intersect( CX, V );
    
    IpJ := DefiningIdeal( HomalgRing( Closure( IpJ ) ) );
    
    J := MatrixOfSubobjectGenerators( IpJ );
    
    J := DecideZero( J, I );
    
    J := CertainRows( J, NonZeroRows( J ) );
    
    return LeftSubmodule( J );
    
end );

##
InstallMethod( QuasiAffineDecomposition,
        "for a constructible set",
        [ IsScheme and IsAlgebraicThomasDecompositionOfConstructibleSetRep ],
        
  function( X )
    local Y, l;
    
    l := [ ];
    
    while not IsEmpty( X ) do
        
        Y := QuasiAffineSet( Closure( X ), ADefiningIdealOfComplement( X ) );
        
        SetClosure( Y, Closure( X ) );
        
        Add( l, Y );
        
        X := Difference( X, Y );
        
    od;
    
    SetIsQuasiAffineSubscheme( X, Length( l ) <= 1 );
    
    return l;
    
end );

InstallMethod( QuasiAffineDecomposition,
        "for a quasi-affine scheme",
        [ IsScheme and IsQuasiAffineSubscheme ],
        
  function( X )
    
    return [ X ];
    
end );


##
InstallMethod( IsQuasiAffineSubscheme,
        "for a constructible set",
        [ IsScheme and IsAlgebraicThomasDecompositionOfConstructibleSetRep ],
        
  function( X )
    
    return Length( QuasiAffineDecomposition( X ) ) <= 1;
    
end );

##
InstallGlobalFunction( VariableForCountingPolynomial,
  function( arg )
    local u;
    
    if not IsBound( ALGEBRAIC_THOMAS.variable_for_counting_polynomial ) then
        
        if Length( arg ) > 0 and IsString( arg[1] ) then
            u := arg[1];
        else
            u := "u";
        fi;
        
        u := Indeterminate( Integers, u );
        
        ALGEBRAIC_THOMAS.variable_for_counting_polynomial := u;
    fi;
    
    return ALGEBRAIC_THOMAS.variable_for_counting_polynomial;
    
end );

##
InstallMethod( CountingPolynomial,
        "for a constructible set",
        [ IsScheme and IsAlgebraicThomasDecompositionOfConstructibleSetRep ],
        
  function( X )
    local u, coeffs, p;
    
    u := VariableForCountingPolynomial( );
    
    if IsEmpty( X ) then
        return 0 * u;
    fi;
    
    coeffs := homalgSendBlocking( [ "(p->map[3](coeff,p,u,[$0..degree(p)]))(AlgebraicThomas[countingPolynomials](", X!.Thomas_system, ",sym='", String( u ), "')[2])" ], "need_output", HOMALG_IO.Pictograms.CountingPolynomial );
    
    coeffs := StringToIntList( coeffs );
    
    p := Sum( [ 1 .. Length( coeffs ) ], i -> coeffs[i] * u^(i - 1) );
    
    SetIsAffineSpace( X, p = u^DimensionOfAmbientSpace( X ) );
    
    return p;
    
end );

##
InstallMethod( CountingPolynomial,
        "for an affine scheme",
        [ IsScheme and IsAffineSchemeRep ],
        
  function( X )
    
    return CountingPolynomial( QuasiAffineSet( X ) );
    
end );

##
InstallMethod( IsAffineSubscheme,
        "for a constructible set",
        [ IsScheme and IsAlgebraicThomasDecompositionOfConstructibleSetRep ],
        
  function( X )
    local R, Xcls;
    
    R := HomalgRing( X );
    
    Xcls := QuasiAffineSet( Closure( X ) );
    
    return CountingPolynomial( X ) = CountingPolynomial( Xcls );
    
end );

##
InstallMethod( DimensionOfAmbientSpace,
        "for a constructible set",
        [ IsScheme and IsAlgebraicThomasDecompositionOfConstructibleSetRep ],
        
  function( X )
    
    return KrullDimension( HomalgRing( X ) );
    
end );

####################################
#
# global functions and operations:
#
####################################

##
InstallMethod( \=,
        "for two constructible sets",
        [ IsScheme and IsConstructibleSubsetOfAffineSpace,
          IsScheme and IsConstructibleSubsetOfAffineSpace ],
        
  function( X, Y )
    local Z;
    
    if not CountingPolynomial( X ) = CountingPolynomial( Y ) then
        return false;
    fi;
    
    Z := Intersect( X, Y );
    
    return CountingPolynomial( X ) = CountingPolynomial( Z );
    
end );

##
InstallMethod( IsSubset,
        "for two constructible sets",
        [ IsScheme and IsConstructibleSubsetOfAffineSpace,
          IsScheme and IsConstructibleSubsetOfAffineSpace ],
        
  function( X, Y )
    
    return CountingPolynomial( Y ) = CountingPolynomial( Intersect( X, Y ) );
    
end );

##
InstallMethod( AlgebraicThomasData,
        "for a homalg ring",
        [ IsHomalgExternalRingInMapleRep ],
        
  function( R )
    local r, c, d, option_table;
    
    if not HasCoefficientsRing( R ) then
        Error( "CoefficientsRing is not set for the ring\n" );
    fi;
    
    r := CoefficientsRing( R );
    
    if IsBound( r!.AlgebraicThomasData ) then
        return r!.AlgebraicThomasData;
    fi;
    
    if not IsFieldForHomalg( r ) then
        Error( "CoefficientsRing is not a field\n" );
    elif not ( HasIsFreePolynomialRing( R ) and IsFreePolynomialRing( R ) ) then
        Error( "ring is not a polynomial ring\n" );
    fi;
    
    c := Characteristic( r );
    
    if HasDegreeOverPrimeField( r ) then
        d := DegreeOverPrimeField( r );
    else
        d := 1;
    fi;
    
    option_table := homalgSendBlocking( [ "AlgebraicThomas[newOptions]()" ], R, HOMALG_IO.Pictograms.define );
    
    r!.AlgebraicThomasData := option_table;
    
    homalgSendBlocking( [ "AlgebraicThomas[AlgebraicThomasOptions](", option_table, ",\"characteristic\",", c, ")" ], "need_command", HOMALG_IO.Pictograms.define );
    
    if d > 1 then
        homalgSendBlocking( [ "AlgebraicThomas[AlgebraicThomasOptions](", option_table, ",\"extension\",[", r!.NameOfPrimitiveElement, ",", r!.MinimalPolynomialOfPrimitiveElement, "])" ], "need_command", HOMALG_IO.Pictograms.define );
    fi;
    
    homalgSendBlocking( [ "AlgebraicThomas[AlgebraicThomasOptions](", option_table, ",\"warnings\",false)" ], "need_command", HOMALG_IO.Pictograms.define );
    
    return option_table;
    
end );

##
InstallGlobalFunction( _ConstructibleSet,
  function( X, R )
    local dim, OX;
    
    dim := EvalString( homalgSendBlocking( [ "AlgebraicThomas[Dimension](", X, ")" ], "need_output", HOMALG_IO.Pictograms.ConstructibleSet ) );
    
    X := rec( Thomas_system := X, ring := R );
    
    #OX := Sheafify( R );
    
    ObjectifyWithAttributes(
            X, TheTypeAlgebraicThomasDecompositionOfConstructibleSet,
            Dimension, dim,
            IsConstructibleSubsetOfAffineSpace, true,
            IsReduced, true,
            BaseRing, CoefficientsRing( R )
            );
    
    return X;
    
end );

##
InstallMethod( QuasiAffineSet,
        "for two homalg ideals",
        [ IsFinitelyPresentedSubmoduleRep and ConstructedAsAnIdeal,
          IsFinitelyPresentedSubmoduleRep and ConstructedAsAnIdeal ],
        
  function( I, J )
    local R, table, i, j, var, X;
    
    if IsOne( I ) or IsZero( J ) then
        ## EmptyScheme
    elif IsOne( J ) then
        ## return Spec( R / I );
    fi;
    
    R := HomalgRing( I );
    
    if not IsIdenticalObj( R, HomalgRing( J ) ) then
        Error( "the underlying rings are not identical\n" );
    fi;
    
    table := AlgebraicThomasData( R );
    
    i := MatrixOfSubobjectGenerators( I );
    j := MatrixOfSubobjectGenerators( J );
    
    if IsZero( i ) then
        i := HomalgZeroMatrix( 1, 1, R );
    fi;
    
    if IsZero( j ) then
        j := HomalgZeroMatrix( 1, 1, R );
    fi;
    
    var := Indeterminates( R );
    var := Reversed( var );
    
    X := homalgSendBlocking( [ "AlgebraicThomas[AlgebraicThomasDecompositionMany](AlgebraicThomas[ineqOr](map(op,convert(", i, ",listlist)),map(op,convert(", j, ",listlist))),[", var, "], use_options=", table, ")" ], "break_lists", HOMALG_IO.Pictograms.ConstructibleSet );
    
    X := _ConstructibleSet( X, R );
    
    X!.DefiningIdeal := I;
    X!.DefiningIdealOfComplement := J;
    SetADefiningIdealOfComplement( X, J );
    SetIsQuasiAffineSubscheme( X, true );
    
    if IsOne( I ) or IsZero( J ) then
        SetIsEmpty( X, true );
    elif IsOne( J ) then
        SetIsAffineSubscheme( X, true );
    fi;
    
    return X;
    
end );

##
InstallMethod( QuasiAffineSet,
        "for a homalg ideal",
        [ IsFinitelyPresentedSubmoduleRep and ConstructedAsAnIdeal ],
        
  function( I )
    
    return QuasiAffineSet( I, I^0 );
    
end );

##
InstallMethod( QuasiAffineSet,
        "for an affine scheme and a homalg ideal",
        [ IsAffineSchemeRep and IsAffine,
          IsFinitelyPresentedSubmoduleRep and ConstructedAsAnIdeal ],
        
  function( X, J )
    local R, I;
    
    R := HomalgRing( X );
    
    if HasIsFreePolynomialRing( R ) and IsFreePolynomialRing( R ) then
        I := ZeroLeftSubmodule( R );
    elif IsHomalgResidueClassRingRep( R ) then
        I := DefiningIdeal( R );
    else
        TryNextMethod( );
    fi;
    
    return QuasiAffineSet( I, J );
    
end );

##
InstallMethod( QuasiAffineSet,
        "for an affine scheme",
        [ IsAffineSchemeRep and IsAffine ],
        
  function( X )
    local R, V;
    
    R := HomalgRing( X );
    
    if IsHomalgResidueClassRingRep( R ) then
        R := AmbientRing( R );
    fi;
    
    V := QuasiAffineSet( X, LeftSubmodule( R ) );
    
    SetClosure( V, X );
    
    return V;
    
end );

##
InstallMethod( QuasiAffineSet,
        "for two affine schemes",
        [ IsAffineSchemeRep and IsAffine,
          IsAffineSchemeRep and IsAffine ],
        
  function( X, Y )
    local R, J;
    
    R := HomalgRing( Y );
    
    if HasIsFreePolynomialRing( R ) and IsFreePolynomialRing( R ) then
        J := ZeroLeftSubmodule( R );
    elif IsHomalgResidueClassRingRep( R ) then
        J := DefiningIdeal( R );
    else
        TryNextMethod( );
    fi;
    
    return QuasiAffineSet( X, J );
    
end );

##
InstallMethod( ConstructibleSet,
        "for a homalg ideal and an empty list",
        [ IsFinitelyPresentedSubmoduleRep and ConstructedAsAnIdeal,
          IsList and IsEmpty ],
        
  function( I, J )
    
    return QuasiAffineSet( I );
    
end );

##
InstallMethod( ConstructibleSet,
        "for an affine scheme and an empty list",
        [ IsAffineSchemeRep and IsAffine,
          IsList and IsEmpty ],
        
  function( X, J )
    
    return QuasiAffineSet( X );
    
end );

##
InstallMethod( ConstructibleSet,
        "for a homalg ideal and a list of polynomials",
        [ IsFinitelyPresentedSubmoduleRep and ConstructedAsAnIdeal,
          IsList ],
        
  function( I, J )
    local R, table, i, var, X;
    
    if IsOne( I ) or IsZero( J ) then
        ## EmptyScheme
    fi;
    
    R := HomalgRing( I );
    
    if ForAny( J, j -> not IsIdenticalObj( R, HomalgRing( j ) ) ) then
        Error( "the underlying rings are not identical\n" );
    fi;
    
    table := AlgebraicThomasData( R );
    
    i := MatrixOfSubobjectGenerators( I );
    
    if IsZero( i ) then
        i := HomalgZeroMatrix( 1, 1, R );
    fi;
    
    var := Indeterminates( R );
    var := Reversed( var );
    
    X := homalgSendBlocking( [ "AlgebraicThomas[AlgebraicThomasDecomposition]([map(op,convert(", i, ",listlist)),[", J, "]],[", var, "],use_options=", table, ")" ], "break_lists", HOMALG_IO.Pictograms.ConstructibleSet );
    
    X := _ConstructibleSet( X, R );
    
    X!.DefiningIdeal := I;
    
    if IsOne( I ) or IsZero( J ) then
        SetIsEmpty( X, true );
    fi;
    
    return X;
    
end );

##
InstallMethod( ConstructibleSet,
        "for an affine scheme and a list of polynomials",
        [ IsAffineSchemeRep and IsAffine,
          IsList ],
        
  function( X, J )
    local R, I;
    
    R := HomalgRing( X );
    
    if HasIsFreePolynomialRing( R ) and IsFreePolynomialRing( R ) then
        I := ZeroLeftSubmodule( R );
    elif IsHomalgResidueClassRingRep( R ) then
        I := DefiningIdeal( R );
    else
        TryNextMethod( );
    fi;
    
    return QuasiAffineSet( I, J );
    
end );

##
InstallMethod( Intersect2,
        "for two constructible sets",
        [ IsScheme and IsAlgebraicThomasDecompositionOfConstructibleSetRep,
          IsScheme and IsAlgebraicThomasDecompositionOfConstructibleSetRep ],
        
  function( X, Y )
    local R, Z;
    
    R := HomalgRing( X );
    
    if not IsIdenticalObj( R, HomalgRing( Y ) ) then
        Error( "the underlying rings are not identical\n" );
    fi;
    
    Z := homalgSendBlocking( [ "AlgebraicThomas[SolIntersect](", X!.Thomas_system, Y!.Thomas_system, ")" ], HOMALG_IO.Pictograms.ConstructibleSet );
    
    Z := _ConstructibleSet( Z, R );
    
    if HasIsQuasiAffineSubscheme( X ) and IsQuasiAffineSubscheme( X ) and
       HasIsQuasiAffineSubscheme( Y ) and IsQuasiAffineSubscheme( Y ) then
        SetIsQuasiAffineSubscheme( Z, true );
    fi;
    
    return Z;
    
end );

##
InstallMethod( Intersect2,
        "for a constructible set and an affine scheme",
        [ IsScheme and IsAlgebraicThomasDecompositionOfConstructibleSetRep,
          IsScheme and IsAffineSchemeRep ],
        
  function( X, Y )
    
    return Intersect2( X, QuasiAffineSet( Y ) );
  
end );

##
InstallMethod( Intersect2,
        "for an affine scheme and a constructible set",
        [ IsScheme and IsAffineSchemeRep,
          IsScheme and IsAlgebraicThomasDecompositionOfConstructibleSetRep ],
        
  function( X, Y )
    
    return Intersect2( QuasiAffineSet( X ), Y );
  
end );

##
InstallMethod( Union2,
        "for two constructible sets",
        [ IsScheme and IsAlgebraicThomasDecompositionOfConstructibleSetRep,
          IsScheme and IsAlgebraicThomasDecompositionOfConstructibleSetRep ],
        
  function( X, Y )
    local R, Z;
    
    R := HomalgRing( X );
    
    if not IsIdenticalObj( R, HomalgRing( Y ) ) then
        Error( "the underlying rings are not identical\n" );
    fi;
    
    Z := homalgSendBlocking( [ "AlgebraicThomas[SolUnion](", X!.Thomas_system, Y!.Thomas_system, ")" ], HOMALG_IO.Pictograms.ConstructibleSet );
    
    return _ConstructibleSet( Z, R );
    
end );

##
InstallMethod( Union2,
        "for a constructible set and an affine scheme",
        [ IsScheme and IsAlgebraicThomasDecompositionOfConstructibleSetRep,
          IsScheme and IsAffineSchemeRep ],
        
  function( X, Y )
    
    return Union2( X, QuasiAffineSet( Y ) );
  
end );

##
InstallMethod( Union2,
        "for an affine scheme and a constructible set",
        [ IsScheme and IsAffineSchemeRep,
          IsScheme and IsAlgebraicThomasDecompositionOfConstructibleSetRep ],
        
  function( X, Y )
    
    return Union2( QuasiAffineSet( X ), Y );
  
end );


##
InstallMethod( Difference,
        "for two constructible sets",
        [ IsScheme and IsAlgebraicThomasDecompositionOfConstructibleSetRep,
          IsScheme and IsAlgebraicThomasDecompositionOfConstructibleSetRep ],
        
  function( X, Y )
    local R, Z;
    
    R := HomalgRing( X );
    
    if not IsIdenticalObj( R, HomalgRing( Y ) ) then
        Error( "the underlying rings are not identical\n" );
    fi;
    
    Z := homalgSendBlocking( [ "AlgebraicThomas[SolDifference](", X!.Thomas_system, Y!.Thomas_system, ")" ], HOMALG_IO.Pictograms.ConstructibleSet );
    
    return _ConstructibleSet( Z, R );
    
end );

##
InstallMethod( Difference,
        "for a constructible set and an affine scheme",
        [ IsScheme and IsAlgebraicThomasDecompositionOfConstructibleSetRep,
          IsScheme and IsAffineSchemeRep ],
        
  function( X, Y )
    
    return Difference( X, QuasiAffineSet( Y ) );
  
end );

##
InstallMethod( Difference,
        "for an affine scheme and a constructible set",
        [ IsScheme and IsAffineSchemeRep,
          IsScheme and IsAlgebraicThomasDecompositionOfConstructibleSetRep ],
        
  function( X, Y )
    
    return Difference( QuasiAffineSet( X ), Y );
  
end );

##
InstallMethod( Difference,
        "for two affine schemes",
        [ IsScheme and IsAffineSchemeRep,
          IsScheme and IsAffineSchemeRep ],
        
  function( X, Y )
    
    return QuasiAffineSet( X, Y );
  
end );

##
InstallMethod( ComplementAttr,
        "for a constructible set",
        [ IsScheme and IsAlgebraicThomasDecompositionOfConstructibleSetRep ],
        
  function( X )
    local Z, C;
    
    Z := homalgSendBlocking( [ "AlgebraicThomas[Complement](", X!.Thomas_system, ")" ], HOMALG_IO.Pictograms.ConstructibleSet );
    
    C := _ConstructibleSet( Z, HomalgRing( X ) );
    
    SetComplementAttr( C, X );
    
    return C;
    
end );

##
InstallMethod( ComplementAttr,
        "for an affine scheme",
        [ IsScheme and IsAffineSchemeRep ],
        
  function( X )
    
    return Complement( QuasiAffineSet( X ) );
    
end );

##
InstallMethod( Project,
        "for a constructible set over a filtered ring",
        [ IsScheme and IsAlgebraicThomasDecompositionOfConstructibleSetRep ],
        
  function( X )
    local R, vars, Xc, Y;
    
    R := HomalgRing( X );
    
    if not HasBaseRing( R ) then
        Error( "the underlying ring is not filtered\n" );
    fi;
    
    R := BaseRing( R );
    
    vars := Indeterminates( R );
    
    ## vars sollen ganz hinten stehen bei HomalgRing( X );
    
    Xc := homalgSendBlocking( [ "AlgebraicThomas[Comprehensive](", X!.Thomas_system, Length( vars ), ")" ], HOMALG_IO.Pictograms.ConstructibleSet );
    
    Y := homalgSendBlocking( [ "map(a->a[1],", Xc, ")" ], HOMALG_IO.Pictograms.ConstructibleSet );
    
    return _ConstructibleSet( Y, R );
    
end );

##
InstallMethod( Project,
        "for an affine scheme over a filtered ring",
        [ IsScheme and IsAffineSchemeRep ],
        
  function( X )
    
    return Project( QuasiAffineSet( X ) );
    
end );

####################################
#
# View, Print, and Display methods:
#
####################################

##
InstallMethod( Display,
        "for a constructible set",
        [ IsScheme and IsAlgebraicThomasDecompositionOfConstructibleSetRep ],
        
  function( X )
    
    homalgDisplay( [ "AlgebraicThomas[printSystem](", X!.Thomas_system , ")" ] );
    
    Print( "A constructible set represented by the above Thomas decomposition\n" );
    
end );
