And-I-Was-Like-Code v0.1 documentation

AWS is purely a C++ translator of the AWS language. No actual
standalone compilation is performed. Hence, most of the functions from 
the standard C and C++ library are available, with the most limiting
exception being classes and structs. They are not available.

To compile a AWS program, put the AWS.pl a place where you can
easily reach it.

From the command line, type this to compile a AWS-program,
and await furher instructions from the script.

$>AWS.pl filename

The g++ compiler WILL pickup any errors from the AWS-translation,
and also inform you about it. In order to make your life a little 
easier, the translated code will be printed out with according line
numbers if the translation goes without errors.

Please note that the following dependencies must be installed for
AWS to work:
-	Perl
-	gcc (g++)

Unless you're on a Windows computer, chances are they are already installed.

Note that AWS is in a ridiculously early stage, and will (hopefully)
be worked on further. No guarantee for anything to work is provided, and
you should be relieved if you even got this text file to open.


#Declaring a function

There is no prototying available at this point in time. Functions must be
defined accordingly. 

The function syntax is as such:


	and the function [name] [vartype] [varname] was like [retval]  
	totally  


Note that the parameters are optional, and more than one can be added. 
As such:
	
	so the function main int argc char** argv was like int
	totally

Which will translate into:

	int main(int argc, char** argv) 
	{
	}


#Declaring a variable

Declaring a variable is straight forward.

	so this int x was like 0
	and this float y was like square 5
	and this float z was like x + y

Obviosly, you can change the value of any variable. 

	so this int x was like 0
	then x was like 4

A variable can also be assigned / reassigned from a function
	
	so this int x was like omg, intFunction

Typecasting is also allowed, but only for function return values.

	then x was like omg, (int)floatFunction


#Calling a function

Calling a function is done in two ways:

	anyway, func param1 param2
	umm so, func param
	umm so, func

C and C++ library functions can be called in this fashion.

	anyway, printf "%d\n" 15


#Declaring a for-loop

For loop is the only available loop in AWS. Also, it is only compatible
with int-values. You don't have any other options, in fact. It is declared
as following:

	so this i was like 0, but then it was like woah, 10
	totally

This is the AWS equivalent of this:

	for (int i=0; i<=10; i++)

Naturally, you are able to count downwards as well:

	so this i was like 10, but then it was like woah, 0

Which is equivalent to:

	for (int i=10; i>=0; i--) 

It's important to note that all loops must be "totally"ed.


#If-else

If-else syntax is pretty straight forward:

	like, oh my god! 1 < 5!		// if (1<5) { 
		// code
	say whaaaat?  				// } else {
		// code
	totally						// } 

Now, notice three things. 

1. 'say whaaaat?' can contain as many a's as you'd like.
2. If the else keyword (say what?) is not included, the if block
	must be totally-ed.
3. THERE IS NO ELSE-IF. Not at all. Use two if-statements instead.


#Comments

Only double-forward-slash comments are valid in AWS.

	// Like so

	/* These comments are invalid, and will be treated as an error. */

HOWEVER! They have to be placed on a separate line. Comments
cannot be placed after an expression.


#Sample program

	so this function print_bottle int num was like void
		anyway
	totally

	so this function main int argc char** argv was like int
		so this i was like 0, but then it was like woah, 10
			and i was like square i
		totally
		xoxo 0
	totally			


#Additional syntax rules  

Additional libraries / header files can be included with the following syntax:

	and the program was like <math.h>

--

As AWS is an experimental project which in turn only translates stuff into
C++ code, it would be impossible, stupid and ridiculous to create a AWS
equivalent of every C++ functionality. Hence, behold the C++-tag! Any code
placed after a pair of square brackets ([], no spaces) will be treated as raw
C++, and avoid translation. The tag is line specific, and must be repeated
for each line you wish to keep as raw C++.

	[]class myClass {	
	[]	int myVar;
	[]};

While this gives you added flexibility in your AWS programs, it should
also hopefully remind you of what a perfectly good waste of time writing code
in this language is. Stop it. Stop it now.

--

Print a newline:

	and i was like duuh


#IMPORTANT NOTICES

- AWS does currently NOT keep track of variable scope. Watch compiler
	output for errors in your syntax.

- All functions and loops must have a coresponding "totally".

- By default, the <iostream> library is included.

- By default, the namespace std is used. All other namespaces are unavailable.

- Do not forget the handyness of prinft. There is no direct key to call
	printf(), as there is with cout. Call it as a regular function:
		'anyway, printf "%d" myInt'

- 'duuh' and 'duh' are unprotected keywords. Please don't use them.









