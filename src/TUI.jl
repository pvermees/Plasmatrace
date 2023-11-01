function prompt(key)
    messages = Dict(
        "welcome" =>
        "===========\n"*
        "Plasmatrace\n"*
        "===========\n",
        "top" =>
        "f: Load the data files\n"*
        "m: Specify a method\n"*
        "s: Mark mineral standards\n"*
        "v: View the data\n"*
        "j: Save the session as .json\n"*
        "c: Export the data as .csv\n"*
        "x: Exit",
        "load" =>
        "i. Specify your instrument [default=Agilent]\n"*
        "r. Read the data\n"*
        "l. List all the samples in the session\n"*
        "x. Exit",
        "method" =>
        "Choose an application:\n"*
        "1. Lu-Hf",
        "standards" =>
        "p. Add a standard by prefix\n"*
        "r. Remove a standard\n"*
        "l. List all the standards\n"*
        "x. Exit",
        "view" =>
        "[Enter]: next\n"*
        "[Space]: previous\n"*
        "b: Select blank window(s)\n"*
        "w: Select signal window(s)\n"*
        "s: Mark as standard\n"*
        "x: Exit",
        "instrument" =>
        "Choose a file format:\n"*
        "1. Agilent",
        "read" =>
        "Enter the full path of the data directory:"
    )
    println(messages[key])
end

function dispatch!(pd::Union{Nothing,run};chain)
    key = chain[end]
    prompt(key)
    response = readline()
    out = "x"
    if key=="top"
        if response=="f"
            out = "load"
        elseif response=="m"
            out = "method"
        elseif response=="s"
            out = "standards"
        elseif response=="v"
            out = "view"
        elseif response=="x"
            out = "x"
        else
            out = unsupported()
        end
    elseif key=="method"
        chooseMethod!(pd,response)
    elseif key=="load"
        if response=="i"
            out = "instrument"
        elseif response=="r"
            out = "read"
        elseif response=="l"
            listSamples(pd)
        elseif response!="x"
            out = unsupported()
        end
    elseif key=="application"
        method_a!(pd,response)
    elseif key=="view"
        viewer(pd)
    elseif key=="instrument"
        load_i!(pd,response)
    elseif key=="read"
        load!(pd,dname=response)
    elseif key=="standards"
        if response=="p"
            addStandardPrefix!(pd)
        elseif response=="r"
            deleteStandards!(pd)
        elseif response=="l"
            listStandards(pd)
        elseif response!="x"
            out = unsupported()
        end
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
        labels = names(getDat(samples[1]))[3:end]
        for i in eachindex(labels)
            println(string(i)*". "*labels[i])
        end
        println("\ncorresponding to the following isotopes or their proxies:")
        println(join(isotopes,","))
        println("For example: "*join(1:size(isotopes,1),","))
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

function viewer(pd)
    i = 1
    while true
        samples = getSamples(pd)
        ns = size(samples,1)
        p = plot(samples[i])
        display(p)
        response = readline()
        if response==""
            i = i<ns ? i+1 : 1
        elseif response==" "
            i = i>1 ? i-1 : ns
        else
            return
        end
        prompt("view")
    end
end

function listSamples(pd)
    snames = getSnames(pd)
    for sname in snames
        println(sname)
    end
end

function addStandardPrefix!(pd)
    println("Enter the prefix of the standards:")
    prefix = readline()
    println("Enter the number of the standard")
    
    number = readline()
    markStandards!(pd,prefix=response,standard=parse(Int,number))
end

function deleteStandard!(pd)
    
end

function listStandards(pd)
    samples = getSnames(pd)
    standards = getStandard(pd)
    println(standards)
end
