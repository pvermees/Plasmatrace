# Plasmatrace.jl

## Julia package for LA-ICP-MS data reduction

Plasmatrace.jl is in early development and is not yet ready for
practical use. For this reason, it has not yet been added to the
[Julia](https://julialang.org/) package repository. However, if you
want to play around with the current functionality, then you can
install the package from GitHub.  At the Julia REPL:

```
import Pkg; Pkg.add(url="https://github.com/pvermees/Plasmatrace.jl")
```

There are two ways to interact with Plasmatrace:

## 1. Interactive, text-based user interface.

Here is an example of a menu-driven Plasmatrace session:

```
julia> using Plasmatrace
julia> PT()
===========
Plasmatrace
===========

f: Load the data files
m: Specify a method
b: Bulk settings
v: View and adjust each sample
p: Process the data
e: Export the results
l: Import/export a session log
x: Exit
f
i. Specify your instrument [default=Agilent]
r. Open and read the data files
l. List all the samples in the session
x. Exit
r
Enter the full path of the data directory:
/home/pvermees/Documents/Plasmatrace/Garnet/
i. Specify your instrument [default=Agilent]
r. Open and read the data files
l. List all the samples in the session
x. Exit
x
f: Load the data files
m: Specify a method
b: Bulk settings
v: View and adjust each sample
p: Process the data
e: Export the results
l: Import/export a session log
x: Exit
b
b. Set default blank windows
s. Set default signal windows
p. Add a standard by prefix
n. Adjust the order of the polynomial fits
r. Remove a standard
l. List all the standards
x. Exit
x
f: Load the data files
m: Specify a method
b: Bulk settings
v: View and adjust each sample
p: Process the data
e: Export the results
l: Import/export a session log
x: Exit
m
Choose an application:
1. Lu-Hf
1
Choose from the following list of channels:

1. Mg24 -> 24
2. Al27 -> 27
3. Ca43 -> 43
4. Ti47 -> 113
5. Fe57 -> 57
6. Sr88 -> 88
7. Y89 -> 172
8. Zr90 -> 173
9. La139 -> 154
10. Ce140 -> 155
11. Pr141 -> 141
12. Nd146 -> 146
13. Sm147 -> 147
14. Yb172 -> 172
15. Lu175 -> 175
16. Lu175 -> 257
17. Hf176 -> 258
18. Hf178 -> 260

and select the channels corresponding to the following isotopes or their proxies:
Lu176,Hf177,Hf176

Specify your selection as a comma-separated list of numbers.
For example: 1,2,3
15,18,17
f: Load the data files
m: Specify a method
b: Bulk settings
v: View and adjust each sample
p: Process the data
e: Export the results
l: Import/export a session log
x: Exit
b
b. Set default blank windows
s. Set default signal windows
p. Add a standard by prefix
n. Adjust the order of the polynomial fits
r. Remove a standard
l. List all the standards
x. Exit
b
Specify the blank windows. The following are all valid entries:

a: automatically select all the windows
(m,M): set a single window from m to M seconds, e.g. (0,20)
(m1,M1),(m2,M2): set multiple windows, e.g. (0,20),(25,30)
a
b. Set default blank windows
s. Set default signal windows
p. Add a standard by prefix
n. Adjust the order of the polynomial fits
r. Remove a standard
l. List all the standards
x. Exit
s
Specify the signal windows. The following are all valid entries:

a: automatically select all the windows
(m,M): set a single window from m to M seconds, e.g. (0,20)
(m1,M1),(m2,M2): set multiple windows, e.g. (0,20),(25,30)
a
b. Set default blank windows
s. Set default signal windows
p. Add a standard by prefix
n. Adjust the order of the polynomial fits
r. Remove a standard
l. List all the standards
x. Exit
p
Enter the prefix(es) of the primary standard(s) as a comma-separated list of strings. For example:
hogsbo_
hogsbo,BP
BP
Now match this/these prefix(es) with the following reference materials:
1. Hogsbo
2. BP
Enter your choice(s) as number or a comma-separated list of numbers,
matching the order in which you entered the prefixes.
2
b. Set default blank windows
s. Set default signal windows
p. Add a standard by prefix
n. Adjust the order of the polynomial fits
r. Remove a standard
l. List all the standards
x. Exit
x
f: Load the data files
m: Specify a method
b: Bulk settings
v: View and adjust each sample
p: Process the data
e: Export the results
l: Import/export a session log
x: Exit
l
s: save session to a log file
r: restore the log of a previous session
x. Exit
s
Enter the path and name of the log file:
test.log
f: Load the data files
m: Specify a method
b: Bulk settings
v: View and adjust each sample
p: Process the data
e: Export the results
l: Import/export a session log
x: Exit
p
Fitting blanks...
Fitting standards...
f: Load the data files
m: Specify a method
b: Bulk settings
v: View and adjust each sample
p: Process the data
e: Export the results
l: Import/export a session log
x: Exit
e
Enter the prefix of the samples to export.
Alternatively, type 'a' to export all the samples.
hogsbo
j: export to .json
c: export to .csv
x. Exit
c
Enter the path and name of the .csv file:
/home/pvermees/Desktop/hogsbo.csv
f: Load the data files
m: Specify a method
b: Bulk settings
v: View and adjust each sample
p: Process the data
e: Export the results
l: Import/export a session log
x: Exit
x

julia>
```

## 2. Command-line API

Here is an example of a Lu-Hf calibration using two mineral standards.
The blanks are fitted using a second order polynomial, whereas the
signal drift is modelled using a linear function:

```
julia> dname = "/home/pvermees/Documents/Plasmatrace/Garnet/";
julia> session = load(dname,instrument="Agilent");
julia> setMethod!(session,method="LuHf",
       channels=["Lu175 -> 175","Hf178 -> 260","Hf176 -> 258"])
julia> setBlanks!(session);
julia> setSignals!(session);
julia> fitBlanks!(session,n=2);
julia> markStandards!(session,prefix="hogsbo_",standard=1);
julia> markStandards!(session,prefix="BP -",standard=2);
julia> fitStandards!(session,refmat=["Hogsbo","BP"],n=1);
julia> p = plot(session,i=15)
julia> display(p)
```