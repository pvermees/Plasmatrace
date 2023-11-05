function DRS!(pd::run;
              method::AbstractString,
              channels::Vector{String})
    DRSmethod!(pd,method=method)
    DRSchannels!(pd,channels=channels)
end
export DRS!

function DRSmethod!(pd::run;method::AbstractString)
    if (method=="LuHf")
        isotopes = ["Lu176","Hf177","Hf176"]
    else
        PTerror("UnknownMethod")
    end
    setMethod!(pd,method)
    setIsotopes!(pd,isotopes)
end

function DRSchannels!(pd::run;channels::AbstractVector)
    isotopes = getIsotopes(pd)
    if size(channels,1)==size(isotopes,1)
        setChannels!(pd,channels)
    else
        PTerror("isochanmismatch")
    end
end

function getExt(instrument)
    if instrument == "Agilent"
        return ".csv"
    else
        PTerror("unknownInstrument")
    end
end
