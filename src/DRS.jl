function DRSprep(pd::run;method="LuHf",refmat="Hogsbo")

    if (method=="LuHf")
        channels = ["Hf176 -> 258","Hf178 -> 260","Lu175 -> 175"]
        AB = getAB(refmat)
    end

    b = blankData(pd,channels=channels)
    s = signalData(pd,channels=channels)

    (A=AB.A,B=AB.B,b=b,s=s)
    
end
