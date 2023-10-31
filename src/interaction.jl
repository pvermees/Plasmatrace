function prompt(key)
    messages = Dict(
        "welcome"
        =>
        "===========\n"*
        "Plasmatrace\n"*
        "===========\n",
        "top"
        =>
        "m: Specify a method\n"*
        "f: Load the data files\n"*
        "s: Mark mineral standards\n"*
        "g: Mark glass standards\n"*
        "v: View the data\n"*
        "j: Save the session as .json\n"*
        "c: Export the data as .csv\n"*
        "x: Exit",
        "view"
        =>
        "[Enter]: next\n"*
        "[Space]: previous\n"*
        "b: Select blank window(s)\n"*
        "w: Select signal window(s)\n"*
        "s: Mark as standard\n"*
        "g: Mark as glass\n"*
        "x: Exit",
        "load"
        =>
        "Enter the path of the data directory:",
        "ext"
        =>
        "Specify the file extension (default = .csv):"
    )
    println(messages[key])
end

function dispatch!(pd::Union{Nothing,run};chain)
    key = chain[end]
    prompt(key)
    response = readline()
    out = nothing
    if (key=="top")
        if (response=="f")
            out = "load"
        elseif (response=="v")
            out = "view"
        elseif (response=="x")
            out = "x"
        else
            unsupported()
        end
    elseif (key=="load")
        out = load(response)
    elseif (key=="view")
        out = interplot(pd)
    else
        unsupported()
    end
    out
end

function PT()
    prompt("welcome")
    myrun = nothing
    chain = ["top"]
    while true
        out = dispatch!(myrun,chain=chain)
        if isa(out,run)
            myrun = out
            pop!(chain)
        elseif out=="x"
            pop!(chain)
            if size(chain,1)<1 return end
        elseif !isnothing(out)
            push!(chain,out)
        end
    end
end
export PT

function unsupported()
    println("This feature is not available yet.\n")
end

function interplot(pd)
    i = 1
    while true
        prompt("view")
        samples = getSamples(pd)
        ns = size(samples,1)
        p = plot(samples[i])
        display(p)
        s = readline()
        if s==""
            i = i<ns ? i+1 : 1
        elseif s==" "
            i = i>1 ? i-1 : ns
        else
            return "x"
        end
    end
end
