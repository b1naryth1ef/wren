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
  assert(vm.interpret(`
    class MyClass {
      construct new() {
        _x = 1
      }

      add(y) {
        return y + _x
      }
    }
  `) == WrenInterpretResult.SUCCESS);


  // Call the constructor
  vm.slots = 1;
  vm.getVariable("main", "MyClass", 0);
  auto myClass = vm.getSlotHandle(0);
  vm.setSlot(0, myClass);
  auto newCallHandle = vm.getCallHandle("new()");
  assert(vm.call(newCallHandle) == WrenInterpretResult.SUCCESS);

  auto classInst = vm.getSlotHandle(0);
  vm.slots = 3;

  vm.setSlot(0, classInst);
  vm.setSlot(1, 5);

  auto addCallHandle = vm.getCallHandle("add(_)");
  assert(vm.call(addCallHandle) == WrenInterpretResult.SUCCESS);
  assert(vm.slots == 1);
  assert(vm.getSlotType(0) == WrenType.NUM);
  assert(vm.getSlot(0).get!double == 6);
}
