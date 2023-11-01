function prompt(key)
    messages = Dict(
        "welcome"
        =>
        "===========\n"*
        "Plasmatrace\n"*
        "===========\n",
        "top"
        =>
        "f: Load the data files\n"*
        "m: Specify a method\n"*
        "s: Mark mineral standards\n"*
        "g: Mark glass standards\n"*
        "v: View the data\n"*
        "j: Save the session as .json\n"*
        "c: Export the data as .csv\n"*
        "x: Exit",
        "method"
        =>
        "Choose an application:\n"*
        "1. Lu-Hf",
        "load"
        =>
        "i. Specify your instrument [default=Agilent]\n"*
        "r. Read the data\n"*
        "x. Exit",
        "view"
        =>
        "[Enter]: next\n"*
        "[Space]: previous\n"*
        "b: Select blank window(s)\n"*
        "w: Select signal window(s)\n"*
        "s: Mark as standard\n"*
        "g: Mark as glass\n"*
        "x: Exit",
        "instrument"
        =>
        "Choose a file format:\n"*
        "1. Agilent",
        "read"
        =>
        "Enter the full path of the data directory:"
    )
    println(messages[key])
end

function dispatch!(pd::Union{Nothing,run};chain)
    key = chain[end]
    prompt(key)
    response = readline()
    out = "x"
    if (key=="top")
        if (response=="f")
            out = "load"
        elseif (response=="m")
            out = "method"
        elseif (response=="v")
            out = "view"
        elseif (response=="x")
            out = "x"
        else
            out = unsupported()
        end
    elseif (key=="method")
        chooseMethod!(pd,response)
    elseif (key=="load")
        if (response=="i")
            out = "instrument"
        elseif (response=="r")
            out = "read"
        elseif (response!="x")
            out = unsupported()
        end
    elseif (key=="application")
        method_a!(pd,response)
    elseif (key=="view")
        interplot(pd)
    elseif (key=="instrument")
        load_i!(pd,response)
    elseif (key=="read")
        load!(pd,dname=response)
    else
        out = unsupported()
    end
    out
end

function PT()
    prompt("welcome")
    myrun = run()
    chain = ["top"]
    while true
        try
            out = dispatch!(myrun,chain=chain)
            if out=="x"
                pop!(chain)
                if size(chain,1)<1 return end
            elseif !isnothing(out)
                push!(chain,out)
            end
        catch e
            println(e)
        end
    end
end
export PT

function unsupported()
    println("This feature is not available yet.\n")
    return nothing
end

function chooseMethod!(pd,response)
    if response=="1"
        method = "LuHf"
    else
        return
    end
    DRSmethod!(pd,method=method)
    isotopes = getIsotopes(pd)
    samples = getSamples(pd)
    if isnothing(isotopes)
        println("Choose a geochronometer first.")
    elseif isnothing(samples)
        println("Load the data first.")
    else
        println("Select the data columns (as a comma-separated list of numbers)\n")
        labels = names(getDat(samples[1]))
        for i in eachindex(labels)
            println(string(i)*". "*labels[i])
        end
        println("\ncorresponding to the following isotopes or their proxies:")
        println(join(isotopes,","))
        println("For example: "*join(3:2+size(isotopes,1),","))
        response = readline()
        selected = parse.(Int,split(response,","))
        DRSchannels!(pd,channels=labels[selected])
    end
end

function load_i!(pd,response)
    instrument = nothing
    if response=="1" instrument = "Agilent"
    else return end
    setInstrument!(pd,instrument)
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
            return
        end
    end
end
