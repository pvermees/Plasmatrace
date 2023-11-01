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

m: Specify a method
f: Load the data files
s: Mark mineral standards
g: Mark glass standards
v: View the data
j: Save the session as .json
c: Export the data as .csv
x: Exit
f
Enter the path of the data directory:
/home/pvermees/Documents/Plasmatrace/MyGarnet/
m: Specify a method
f: Load the data files
s: Mark mineral standards
g: Mark glass standards
v: View the data
j: Save the session as .json
c: Export the data as .csv
x: Exit
v
[Enter]: next
[Space]: previous
b: Select blank window(s)
w: Select signal window(s)
s: Mark as standard
g: Mark as glass
x: Exit

[Enter]: next
[Space]: previous
b: Select blank window(s)
w: Select signal window(s)
s: Mark as standard
g: Mark as glass
x: Exit
x
m: Specify a method
f: Load the data files
s: Mark mineral standards
g: Mark glass standards
v: View the data
j: Save the session as .json
c: Export the data as .csv
x: Exit
x

julia>
```

## 2. Command-line API

Here is an example of a Lu-Hf calibration using two mineral standards.
The blanks are fitted using a second order polynomial, whereas the
signal drift is modelled using a linear function:

```
julia> dname = "/home/pvermees/Documents/Plasmatrace/MyGarnet/";
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