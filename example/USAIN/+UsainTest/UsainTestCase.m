classdef (SharedTestFixtures = {Unittest.fixtures.RandomNumberGeneratorFixture(0), ...
                                Unittest.fixtures.SilentlyLogWarningsFixture}) ...
         UsainTestCase < Unittest.TestCase
    % Extends Unittest.TestCase with functionality shared by various classes in
    % the +UsainTest package

end
