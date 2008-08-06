use Test::More tests => 15;

use strict;
use warnings;

use FindBin;

use lib "$FindBin::Bin/lib";

BEGIN {
	use_ok('Test::Schema');
	use_ok('DBICx::TestDatabase');
	use_ok('DBIx::Class::AutoColumn');
}

my $schema		= new DBICx::TestDatabase 'Test::Schema';
my $rsProduct	= $schema->resultset('Product');
my $product		= $rsProduct->create({ id => 1, name => 'Shiny Widgets' });

cmp_ok($product->id, '==', 1, 'serial identifier is 1');
cmp_ok($product->id_29x_hexadecimal, 'eq', '0000001d', 'serial identifier * 29 in padded 32-bit hexadecimal is 0000001d');
cmp_ok($product->name, 'eq', 'Shiny Widgets', 'product name is "Shiny Widgets"');
cmp_ok($product->name_url_safe, 'eq', 'shiny-widgets', 'URL-safe name is shiny-widgets');

$product->name('REALLY GREAT STUFF!!!!11@#$%');
$product->update;

$product->discard_changes;

cmp_ok($product->id, '==', 1, 'serial identifier is 1');
cmp_ok($product->id_29x_hexadecimal, 'eq', '0000001d', 'serial identifier * 29 in padded 32-bit hexadecimal is 0000001d');
cmp_ok($product->name, 'eq', 'REALLY GREAT STUFF!!!!11@#$%', 'product name is "REALLY GREAT STUFF!!!!11@#$%"');
cmp_ok($product->name_url_safe, 'eq', 'really-great-stuff-11', 'URL-safe name is really-great-stuff-11');

$product->update({ id => 42, name => 'BFG 9000', name_url_safe => 'ignore me' });

$product->discard_changes;

cmp_ok($product->id, '==', 42, 'serial identifier is 42');
cmp_ok($product->id_29x_hexadecimal, 'eq', '000004c2', 'serial identifier * 29 in padded 32-bit hexadecimal is 000004c2');
cmp_ok($product->name, 'eq', 'BFG 9000', 'product name is "BFG 9000"');
cmp_ok($product->name_url_safe, 'eq', 'bfg-9000', 'URL-safe name is bfg-9000');

