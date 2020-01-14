defmodule RailwayIpc.UtilsTest do
  use ExUnit.Case
  alias RailwayIpc.Utils

  describe "module_defined?/1" do
    test "returns false if module not defined" do
      refute Utils.module_defined?(Something.That.Is.Not.Defined)
      refute Utils.module_defined?(Something)
    end

    test "returns true if module is defined" do
      assert Utils.module_defined?(Utils)
      assert Utils.module_defined?(__MODULE__)
    end
  end

  describe "module_defines_function?/2" do
    test "returns true if module has function" do
      assert Utils.module_defines_function?(Utils, :module_defined?)
    end

    test "returns false if module does not have function" do
      refute Utils.module_defines_function?(Utils, :unknown_function!)
    end
  end

  describe "module_defines_functions?/2" do
    test "returns true if module has all functions" do
      assert Utils.module_defines_functions?(Utils, [:module_defined?, :module_defines_function?])
    end

    test "returns false if module is missing any function" do
      refute Utils.module_defines_functions?(Utils, [:module_defined?, :unknown_function!])
    end
  end
end
