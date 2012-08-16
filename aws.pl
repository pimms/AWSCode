# Free to use, distribute and modify as long as the original author is given
# credit, and this notice (line 1-3) is not removed or modified.
# Copyright 2012, Joakim Stien

use strict;
use warnings;
use vars qw[ $_FOUT $_INVALID ];   	# IMPORTANT
use vars qw[ $_INDENTATION ];		# TRIVIAL

# OFTEN USED REGULAR EXPRESSIONS:
# Typenames - function names, var names:
#	(_|\w)+[a-zA-Z0-9_]*
# Expressions (x*x, 2*2.5, etc)	
#	([0-9]\.*[0-9]*|\".*\"|(_|\w)+[a-zA-Z0-9_]*|(((_|\w)+[a-zA-Z0-9_]*|[0-9]\.*[0-9]*)(\s*[\+\-\*\/]\s*((_|\w)+[a-zA-Z0-9_]*|[0-9]\.*[0-9]*))+))

# EXPLANATION OF GLOBALS
# $_FOUT: 
#	the string literal of the C++-file to be. 
#	All validation subroutines append to this string directly
#	if an input expression 
#
# $_INVALID: 
# 	If an error occurs, $_INVALID will be flagged as 1.
# 	The program will not compile jack if _INVALID is flagged.
#
# $_INDENTATION
#	The current level of indentation. Purely for making the C++ output
#	more readable.
#

if (gccExists()) {
	print "GCC found!\n";
} else {
	die "Error: could not find GCC.\n";
}

if ($#ARGV == -1) {
	printHelp(); die;
}

parseAWSCode_Cpp();



#####  PRIMARY SUBROUTINES  #####
sub parseAWSCode_Cpp
{
	my $filename = shift @ARGV;
	my $fh;
	if (!open $fh, "<", $filename) {
		die "Error: could not find file $filename.\n";
	}

	print "Parsing...\n\n";

	$_FOUT = "#include <iostream>;\nusing namespace std;\n\n";

	my $line = 0;
	while (<$fh>)
	{
		$line++;
		chomp;
		next if (!$_);
		next if ($_ =~ m/^\s+$/);

		if (!validateExpression($_))
		{
			print "Syntax error on line $line.\n";
			$_INVALID = 1;
		}
		else
		{
			print "Line $line OK!\n";
		}
	}
	close $fh;

	if ($_INVALID) {
		die "Unable to continue. Errors were found.\n";
	}

	open  $fh, ">", "tmp.cpp";
	print $fh $_FOUT;
	close $fh;

	print "No errors in file $filename.\n\n";
	print "C++ code:\n$_FOUT\n";

	my $output = system("g++ tmp.cpp");

	if (length $output < 2)
	{
		$filename =~ s/\.\w+$//;
		rename("a.out", "$filename");
		system("rm tmp.cpp");
		
		print "Program compiled successfully: $filename\n";
		print "Run the command './$filename' to run the program.\n\n";
	}
	else
	{
		print "\nFailed to compile. Check the compilation errors.\n";
	}
}

#####  VALIDATION SUBROUTINES  #####
sub validateExpression
{
	my $expr = shift;

	if (valRawCpp($expr))			{return 1;}
	if (valComment($expr))			{return 1;}
	if (valInclude($expr)) 			{return 1;}
	if (valFunction($expr)) 		{return 1;}
	if (valClosingBrackets($expr)) 	{return 1;}
	if (valVariable($expr)) 		{return 1;}
	if (valPrint($expr))			{return 1;}
	if (valFunctionCall($expr))		{return 1;}
	if (valReturn($expr))			{return 1;}
	if (valForLoop($expr))			{return 1;}
	if (valIf($expr))				{return 1;}
	if (valElse($expr))				{return 1;}
	0;
}

# valSubs are named after their C-counterpart.
sub valRawCpp
{
	my $expr = shift;
	if ($expr =~ m/^\s*\[\].*$/)
	{
		$expr =~ s/^\s*\[\]//;
		$_FOUT .= "    "x$_INDENTATION.$expr."\n";
		return 1;
	}
	return 0;
}
sub valComment
{
	my $expr = shift;
	return $expr =~ m/^\s*\/\/.*$/;
}
sub valInclude
{
	# so the program was like [lib]
	my $expr = shift;
	if ($expr =~ m/\s*(so|and) the program was like ["<]{1}\w+\.*\w+[">"]{1}\s*$/) {
		$expr =~ s/\s*(so|and) the program was like//;
		$expr =~ s/\s//;
		$_FOUT .= "#include $expr\n";
		return 1;
	}
	0;
}
sub valFunction
{
	# and the function [NAME] [PTYPE] [PNAME] and [PTYPE] [PNAME] was like [RETTYPE]
	my $expr = shift;
	if ($expr =~ m/^\s*(so|and) the function\s+(_|\w)+[a-zA-Z0-9_]*\s+((_|\w)+[a-zA-Z0-9_]*\*{0,2}\s+\*?(_|\w)+[a-zA-Z0-9_]*\s+)*was like (_|\w)+[a-zA-Z0-9_]*\s*$/) {
		$expr =~ s/(\s*(so|and) the function)//;
		$expr =~ s/was like//;

		my @params = split " ", $expr;
		my ($type,$func) = (pop @params, shift @params);

		if ($type eq "duuh" || $type eq "duh") {
			$type = "void"
		}

		$_FOUT .= "$type $func(";

		# Print the function parameters
		if (scalar @params != 0) {
			for (0..$#params/2) {
				$_FOUT .= "$params[$_*2] $params[$_*2+1]";

				if ($_*2+1 < $#params) {
					$_FOUT .= ", ";
				}
			}
		}

		$_FOUT .= ")\n{\n";
		$_INDENTATION++;

		return 1;
	}

	return 0;
}
sub valClosingBrackets
{
	my $expr = shift;
	if ($expr =~ m/^\s*(like, ){0,1}totally\s*$/) {
		$_INDENTATION--;
		$_FOUT .= "    "x$_INDENTATION."}\n";
		return 1;
	}
	return 0;
}
sub valVariable
{
	my $expr = shift;

	# INITIALIZE FROM EXPRESSION: "int x = 2 * y"
	if ($expr =~ m/^\s*(so|and) this\s+(_|\w)+[a-zA-Z0-9_]*\s+(_|\w)+[a-zA-Z0-9_]*\s+was like\s+((_|\w)+[a-zA-Z0-9_]*|[0-9]\.*[0-9]*|".*"|(((_|\w)+[a-zA-Z0-9_]*|[0-9]\.*[0-9]*)(\s*[\+\-\*\/]\s*((_|\w)+[a-zA-Z0-9_]*|[0-9]\.*[0-9]*))+))\s*$/)
	{
		$expr =~ s/(so|and) this\s+//;
		$expr =~ s/ was like//;
		my @cont = split(" ", $expr);
		$_FOUT .= "    "x$_INDENTATION.shift(@cont)." ".shift(@cont)." = ";
		for (@cont) {$_FOUT .= "$_ ";}
		$_FOUT .= ";\n";
		return 1;
	}

	# INITIALIZE FROM FUNCTION: "int x = func(x)"
	if ($expr =~ m/^\s*(so|and) this\s+(_|\w)+[a-zA-Z0-9_]*\s+(_|\w)+[a-zA-Z0-9_]*\s+was like omg,\s+(_|\w)+[a-zA-Z0-9_]*\s*(([0-9]\.*[0-9]*|".*"|(_|\w)+[a-zA-Z0-9_]*|(((_|\w)+[a-zA-Z0-9_]*|[0-9]\.*[0-9]*)(\s*[\+\-\*\/]\s*((_|\w)+[a-zA-Z0-9_]*|[0-9]\.*[0-9]))))+\s*)*$/)
	{
		$expr =~ s/^\s*(so|and) this\s+//;
		$expr =~ s/s*was like omg,//;
		
		my @cont = split(" ", $expr);
		my $open_quote = 0;
		$_FOUT .= "    "x$_INDENTATION.shift(@cont)." ".shift(@cont)." = ".shift(@cont)."(";
		for (0..$#cont) {
			$_FOUT .= $cont[$_];
			if ($cont[$_] =~ m/.*".*/) {$open_quote = !$open_quote;}
			if (!$open_quote) {
				if ($_ != $#cont) {
					$_FOUT .= ", ";
				}
			} else {
				$_FOUT .= " ";
			}
		}
		$_FOUT .= ");\n";

		return 1;
	}


	# BUGGY MOTHERFUCK!!

	# REASSIGNMENT FROM EXPRESSION
	if ($expr =~ m/^\s*then\s+(_|\w)+[a-zA-Z0-9_]*\s+was like\s+((_|\w)+[a-zA-Z0-9_]*|[0-9]\.*[0-9]*|".*"|(((_|\w)+[a-zA-Z0-9_]*|[0-9]\.*[0-9]*)(\s*[\+\-\*\/]\s*((_|\w)+[a-zA-Z0-9_]*|[0-9]\.*[0-9]*))+))\s*$/)
	{
		$expr =~ s/\s*then //;
		$expr =~ s/ was like//;
		my @cont = split(" ", $expr);
		$_FOUT .= "    "x$_INDENTATION.shift(@cont)." = ";
		for (@cont) {$_FOUT .= "$_ ";}
		$_FOUT .= ";\n";
		return 1;
	}

	# REASSIGNMENT FROM FUNCTION
	if ($expr =~ m/^\s*then\s+(_|\w)+[a-zA-Z0-9_]*\s+was like omg,\s+(_|\w)+[a-zA-Z0-9_]*\s*(([0-9]\.*[0-9]*|".*"|(_|\w)+[a-zA-Z0-9_]*|(((_|\w)+[a-zA-Z0-9_]*|[0-9]\.*[0-9]*)(\s*[\+\-\*\/]\s*((_|\w)+[a-zA-Z0-9_]*|[0-9]\.*[0-9]))))+\s*)*$/)
	{
		$expr =~ s/\s*then //;
		$expr =~ s/s*was like omg,//;
		
		my @cont = split(" ", $expr);
		my $open_quote = 0;
		$_FOUT .= "    "x$_INDENTATION.shift(@cont)." = ".shift(@cont)."(";
		for (0..$#cont) {
			$_FOUT .= $cont[$_];
			if ($cont[$_] =~ m/.*".*/) {$open_quote = !$open_quote;}
			if (!$open_quote) {
				if ($_ != $#cont) {
					$_FOUT .= ", ";
				}
			} else {
				$_FOUT .= " ";
			}
		}
		$_FOUT .= ");\n";

		return 1;
	}

	return 0;
}
sub valPrint
{
	my $expr = shift;

	# Printing an expression
	if ($expr =~ m/^\s*(so|and) [iI] was like\s+([0-9]\.*[0-9]*|".*"|(_|\w)+[a-zA-Z0-9_]*|(((_|\w)+[a-zA-Z0-9_]*|[0-9]\.*[0-9]*)(\s*[\+\-\*\/]\s*((_|\w)+[a-zA-Z0-9_]*|[0-9]\.*[0-9]*))+))\s*$/)
	{
		$expr =~ s/\s*(so|and) [iI] was like\s+//;

		if ($expr eq "duuh") {
			$_FOUT .= "    "x$_INDENTATION."cout<<endl;\n";
		} else {
			$_FOUT .= "    "x$_INDENTATION."cout<<$expr <<endl;\n";
		}	
		return 1;
	}

	# Printing a function return
	if ($expr =~ m/^\s*(so|and) [iI] was like\s+(_|\w)+[a-zA-Z0-9_]*\s+(([0-9]\.*[0-9]*|".*"|(_|\w)+[a-zA-Z0-9_]*|(((_|\w)+[a-zA-Z0-9_]*|[0-9]\.*[0-9]*)(\s*[\+\-\*\/]\s*((_|\w)+[a-zA-Z0-9_]*|[0-9]\.*[0-9]*))))\s*)+$/)
	{
		$expr =~ s/\s*(so|and) [iI] was like\s+//;

		$_FOUT .= "    "x$_INDENTATION."cout<<";

		my @cont = split(" ", $expr);
		my $open_quote = 0;
		$_FOUT .= "    "x$_INDENTATION.shift(@cont)."(";
		for (0..$#cont) {
			$_FOUT .= $cont[$_];
			if ($cont[$_] =~ m/.*".*/) {$open_quote = !$open_quote;}
			if (!$open_quote) {
				if ($_ != $#cont) {
					$_FOUT .= ", ";
				}
			} else {
				$_FOUT .= " ";
			}
		}
		$_FOUT .= ") <<endl;\n";

		return 1;
	}

	return 0;
}
sub valFunctionCall
{
	my $expr = shift;
	if ($expr =~ m/^\s*(anyway|umm so),\s+(_|\w)+[a-zA-Z0-9_]*\s*(([0-9]\.*[0-9]*|".*"|(_|\w)+[a-zA-Z0-9_]*|(((_|\w)+[a-zA-Z0-9_]*|[0-9]\.*[0-9]*)(\s*[\+\-\*\/]\s*((_|\w)+[a-zA-Z0-9_]*|[0-9]\.*[0-9]))))+\s*)*$/)
	{
		$expr =~ s/\s*(anyway|umm so), //;

		my @cont = split(" ", $expr);
		my $open_quote = 0;
		$_FOUT .= "    "x$_INDENTATION.shift(@cont)."(";
		for (0..$#cont) {
			$_FOUT .= $cont[$_];
			if ($cont[$_] =~ m/.*".*/) {$open_quote = !$open_quote;}
			if (!$open_quote) {
				if ($_ != $#cont) {
					$_FOUT .= ", ";
				}
			} else {
				$_FOUT .= " ";
			}
		}
		$_FOUT .= ");\n";
		return 1;
	}
	return 0;
}
sub valReturn
{
	my $expr = shift;
	if ($expr =~ m/^\s*xoxo\s*([0-9]\.*[0-9]*|\".*\"|(_|\w)+[a-zA-Z0-9_]*|(((_|\w)+[a-zA-Z0-9_]*|[0-9]\.*[0-9]*)(\s*[\+\-\*\/]\s*((_|\w)+[a-zA-Z0-9_]*|[0-9]\.*[0-9]*))+))*\s*$/)
	{
		$expr =~ s/\s*xoxo\s*//;
		$_FOUT .= "    "x$_INDENTATION."return $expr;\n";
		return 1;
	}
	return 0;
}
sub valForLoop
{
	my $expr = shift;
	if ($expr =~ m/^\s*(so|and) this\s+(_|\w)+[a-zA-Z0-9_]*\s+was like [0-9+, but then it was like woah, [0-9]+\s*$/)
	{
		$expr =~ s/\s*(so|and) this\s+//;
		$expr =~ s/\s+was like//;
		$expr =~ s/, but then it was like woah,//;

		my ($name,$begin,$end) = split(" ", $expr);
		$_FOUT .= "    "x$_INDENTATION;
		$_FOUT .= "for (int $name=$begin; $name".(($begin>=$end)?">=":"<=")."$end; $name".(($begin >= $end)?"--":"++").")\n";
		$_FOUT .= "    "x$_INDENTATION."{\n";
		$_INDENTATION++;

		return 1;
	}
	return 0;
}
sub valIf
{
	my $expr = shift;
	if ($expr =~ m/^\s*like, oh my god! .*!\s*$/)
	{
		$expr =~ s/\s*like, oh my god! //;
		$expr =~ s/!\s*$//;

		$_FOUT .= "    "x$_INDENTATION."if ($expr){\n";
		$_INDENTATION++;

		return 1;
	}
	return 0;
}
sub valElse
{
	my $expr = shift;
	if ($expr =~ m/^\s*say wh(a)+t(!|\?)+\s*$/)
	{
		$_FOUT .= "} else {\n";
		return 1;
	}
	return 0;
}

#####  HELPER SUBROUTINES  And-I-Was-Like-Code [AWSCode]
sub gccExists
{
	my $response = `gcc`;
	if ($response =~ m/fbc.pl/i) 
		{return 0;}
	else 
		{return 1;}
}
sub printHelp
{
	print "And-I-Was-Like-Code [AWSCode] v0.1\n\n";
	print "This program parses a valid AWSCode file\n";
	print "and translates it into C-code, then compiles it using GCC.\n";
	print "See syntaxdemo.txt for example usage.\n\n";
	print "Arguments:\n";
	print "\t-h\tdisplay this screen.\n";
	print "\n";
}