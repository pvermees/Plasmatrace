function DRSprep!(pd::run;method="LuHf",refmat="Hogsbo")

    if (method=="LuHf")
        channels = ["Hf176 -> 258","Hf178 -> 260","Lu175 -> 175"]
        AB = getAB(refmat)
    end

    setChannels!(pd,channels)
    b = blankData(pd)  # TODO: blank for all samples
    s = signalData(pd) # TODO: signal just for standards

    (A=AB.A,B=AB.B,b=b,s=s)
    
end
