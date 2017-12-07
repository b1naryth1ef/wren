module wren.vm;

import std.variant : Variant;
import std.string : toStringz, fromStringz;
import wren.core;

class VMConfig {
  WrenConfiguration config;

  this() {
    wrenInitConfiguration(&this.config);
  }
}

class VM {
  private WrenVM* vm;

  this() {
    this(new VMConfig);
  }

  this(VMConfig config) {
    this.vm = wrenNewVM(&config.config);
  }

  ~this() {
    wrenFreeVM(this.vm);
  }

  @property int slots() {
    return wrenGetSlotCount(this.vm);
  }

  @property void slots(int value) {
    return wrenEnsureSlots(this.vm, value);
  }

  WrenInterpretResult interpret(string contents) {
    return wrenInterpret(this.vm, toStringz(contents));
  }

  WrenType getSlotType(int slot) {
    return wrenGetSlotType(this.vm, slot);
  }

  WrenHandle* getSlotHandle(int slot) {
    return wrenGetSlotHandle(this.vm, slot);
  }

  WrenHandle* getCallHandle(string signature) {
    return wrenMakeCallHandle(this.vm, toStringz(signature));
  }

  void getVariable(string moduleName, string name, int slot) {
    wrenGetVariable(this.vm, toStringz(moduleName), toStringz(name), slot);
  }

  Variant getSlot(int slot) {
    Variant result = null;
    final switch (this.getSlotType(slot)) {
      case WrenType.BOOL:
        result = wrenGetSlotBool(this.vm, slot);
        break;
      case WrenType.NUM:
        result = wrenGetSlotDouble(this.vm, slot);
        break;
      case WrenType.FOREIGN:
        result = wrenGetSlotForeign(this.vm, slot);
        break;
      case WrenType.LIST:
        // TODO
        break;
      case WrenType.STRING:
        result = fromStringz(wrenGetSlotString(this.vm, slot));
        break;
      case WrenType.UNKNOWN:
      case WrenType.NULL:
        break;
    }

    return result;
  }

  void setSlot(int slot, WrenHandle* handle) {
    wrenSetSlotHandle(this.vm, slot, handle);
  }

  void setSlot(int slot, double value) {
    wrenSetSlotDouble(this.vm, slot, value);
  }

  WrenInterpretResult call(WrenHandle* method) {
    return wrenCall(this.vm, method);
  }
}

unittest {
  import std.stdio;

  auto vm = new VM;
  assert(vm.interpret("1 + 1") == WrenInterpretResult.SUCCESS);

  vm = new VM;
  assert(vm.interpret("class MyPlugin { static test(x, y) { x + y } }") == WrenInterpretResult.SUCCESS);

  vm.slots = 3;
  vm.getVariable("main", "MyPlugin", 0);

  auto pluginClass = vm.getSlotHandle(0);
  vm.setSlot(0, pluginClass);

  auto callHandle = vm.getCallHandle("test(_,_)");
  vm.setSlot(1, 5);
  vm.setSlot(2, 10);

  assert(vm.call(callHandle) == WrenInterpretResult.SUCCESS);

  writefln("wut: %s, result = %s", vm.slots, vm.getSlot(0));
}
