@testset "load" begin loaddat = loadtest() end
@testset "plot" begin plottest() end
@testset "window" begin windowout = windowtest() end
@testset "plotwindow" begin plotwindowtest() end
@testset "blank" begin blankout = blanktest() end
@testset "method" begin methodout = methodtest() end
@testset "forward" begin forwardout = forwardtest() end
@testset "standard" begin standardout = standardtest() end
