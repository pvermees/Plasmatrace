function channelMessage(pd,pars)
    isotopes = getIsotopes(pd)
    samples = getSamples(pd)
    if isnothing(isotopes)
        println("Choose a geochronometer first.")
    elseif isnothing(samples)
        println("Load the data first.")
    else
        println("Choose from the following list of channels:\n")
        labels = names(getDat(samples[1]))[3:end]
        for i in eachindex(labels)
            println(string(i)*". "*labels[i])
        end
    end
end

function chooseChannelMessage(pd,pars)
    isotopes = getIsotopes(pd)
    channelMessage(pd,pars)
    println("\nand select the channels corresponding to " *
            "the following isotopes or their proxies: ")
    println(join(isotopes,","))
    println("Specify your selection as a comma-separated list of numbers:")
end

function viewChannelMessage(pd,pars)
    channelMessage(pd,pars)
    println("\nSpecify your selection as a comma-separated list of numbers:")
end

function setDenMessage(pd,pars)
    println("Choose one of the following denominators:")
    for i in eachindex(pars.channels)
        println(string(i)*". "*pars.channels[i])
    end
    println("or")
    println("r. No denominator. Plot the raw signals")
end

function chooseRefMatMessage(pd,pars)
    nst = size(unique(getStandard(pd)),1)
    if nst>2
        println("Now match this/these prefix(es) with "*
                "the following reference materials:")
    else
        println("Now match this prefix with one of "*
                "the following reference materials:")
    end
    method = getMethod(pd)
    if isnothing(method) PTerror("undefinedMethod") end
    refMats = collect(keys(referenceMaterials[method]))
    for i in eachindex(refMats)
        println(string(i)*". "*refMats[i])
    end
    if nst>2
        println("Enter your choices as number or a comma-separated list of "*
                "numbers matching the order in which you entered the prefixes.")
    end
end

function setNblankMessage(pd,pars)
    println("Enter a positive (n>0) integer value (currently n="*
            string(pars.n[1])*")")
end
function setNdriftMessage(pd,pars)
    println("Enter a positive (n>0) integer value (currently n="*
            string(pars.n[2])*")")
end
function setNdownMessage(pd,pars)
    println("Enter a non-negative (n>=0) integer value (currently n="*
            string(pars.n[3])*")")
end
