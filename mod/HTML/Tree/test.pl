######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .

use HTML::Tree;
BEGIN { $| = 1; print "1..2\n"; }
END { print "not ok 1\n" unless $loaded; }
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

@data = (
	{	name	=> 'Santa Claus',
		address	=> 'North Pole',
		phone	=> '000-555-1212',
	},
	{	name	=> 'Paul J. Lucas',
		address	=> 'Silicon Valley',
		phone	=> '650-555-1212',
	},
);

package Record;

sub new {
	my $that = shift;
	my $class = ref( $that ) || $that;
	my $this = { };
	return bless $this, $class;
}

package main;

sub fetchrow {
	my( $object, $node, $class, $is_end_tag ) = @_;
	return 1 if $is_end_tag;

	##
	# Pretend each element of @data is a tuple from a result of a database
	# query.  Then each shift is equivalent to getting the next tuple.  If
	# there's no more data, we're done.
	##
	return !!( $object->{ data } = shift @data );
}

sub sub_val {
	my( $object, $node, $class, $is_end_tag ) = @_;
	return 0 if $is_end_tag;

	##
	# Substitute the text of the text_node child of us, a <TD> element.
	##
	($node->children())[0]->text( $object->{ data }->{ $class } );
	return 1;
}

%class_map = (
	loop	=> \&fetchrow,
	name	=> \&sub_val,
	address	=> \&sub_val,
	phone	=> \&sub_val,
);

sub visitor {
	my( $object, $node, $depth, $is_end_tag ) = @_;

	if ( $node->is_text() ) {
		$out .= ( "    " x $depth ) . $node->text() . "\n";
		return 1;
	}

	my $result = 0;
	for ( split( /\s+/, $node->att( 'class' ) ) ) {
		if ( my $func = $class_map{ $_ } ) {
			$result = $func->( $object, $node, $_, $is_end_tag );
			return 0 unless $is_end_tag || $result;
			last;
		}
	}

	$out .= "    " x $depth;

	if ( $is_end_tag ) {
		$out .= "</" . $node->name() . ">\n";
		return $result;
	}

	$out .= '<' . $node->name();

	my $atts = $node->atts();
	while ( my( $k, $v ) = each %{ $atts } ) {
		$out .= " $k=\"$v\"";
	}
	$out .= ">\n";

	return 1;
}

$html = HTML::Tree->new( '../../../test.html' );
$record = Record->new();
$html->visit( $record, \&visitor );

$out =~ s/^\s*\n//gm;
print "not " if $out ne join( '', <DATA> );
print "ok 2\n";

__DATA__
<html lang="en-US">
    <!-- this is a comment -->
    <head>
        <title>
            Sample
        </title>
    </head>
    <body bgcolor="#FFFFFF">
        <table border="border">
            <tr>
                <th>
                    Name
                </th>
                <th>
                    Address
                </th>
                <th>
                    Phone
                </th>
            </tr>
            <tr class="loop">
                <td align="left" class="name">
                    Santa Claus
                </td>
                <td class="address">
                    North Pole
                </td>
                <td class="phone">
                    000-555-1212
                </td>
            </tr>
            <tr class="loop">
                <td align="left" class="name">
                    Paul J. Lucas
                </td>
                <td class="address">
                    Silicon Valley
                </td>
                <td class="phone">
                    650-555-1212
                </td>
            </tr>
        </table>
    </body>
</html>
