require File.join(File.dirname(__FILE__), 'helper')

class TestDeleteParanoid < Test::Unit::TestCase
  context 'with paranoid class' do
    setup do
    end
    context 'when on instance destroyed' do
      should 'not be included in total count' do
        fail
      end
    end
  end
end
