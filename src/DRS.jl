function setMethod!(pd::run;
                    method::String,
                    channels::Vector{String})
    isotopes = nothing
    if (method=="LuHf")
        isotopes = ["Lu176","Hf177","Hf176"]
    else
        PTerror("UnknownMethod")
    end
    setMethod!(pd,method)
    setIsotopes!(pd,isotopes)
    if size(channels,1)==size(isotopes,1)
        setChannels!(pd,channels)
    else
        PTerror("isochanmismatch")
    end
end
export setMethod!

function getExt(instrument)
    if instrument == "Agilent"
        return ".csv"
    else
        PTerror("unknownInstrument")
    end
end
