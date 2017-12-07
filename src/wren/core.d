module wren.core;

extern (C) {
  void wrenInitConfiguration(WrenConfiguration*);

  WrenVM* wrenNewVM(WrenConfiguration*);
  void wrenFreeVM(WrenVM*);
  void wrenCollectGarbage(WrenVM*);

  WrenInterpretResult wrenInterpret(WrenVM*, const char*);
  WrenInterpretResult wrenCall(WrenVM*, WrenHandle*);
  WrenHandle* wrenMakeCallHandle(WrenVM*, const char*);

  // Writing Slots
  void wrenEnsureSlots(WrenVM*, int);
  void wrenSetSlotBool(WrenVM*, int, bool);
  void wrenSetSlotBytes(WrenVM*, int, const char*, size_t);
  void wrenSetSlotDouble(WrenVM*, int, double);
  void wrenSetSlotNewForeign(WrenVM*, int, int, size_t);
  void wrenSetSlotNewList(WrenVM*, int);
  void wrenSetSlotNull(WrenVM*, int);
  void wrenSetSlotString(WrenVM*, int, const char*);
  void wrenSetSlotHandle(WrenVM*, int, WrenHandle*);

  // Reading Slots
  int wrenGetSlotCount(WrenVM*);
  WrenType wrenGetSlotType(WrenVM*, int);
  bool wrenGetSlotBool(WrenVM*, int);
  double wrenGetSlotDouble(WrenVM*, int);
  void* wrenGetSlotForeign(WrenVM*, int);
  const(char*) wrenGetSlotString(WrenVM*, int);
  WrenHandle* wrenGetSlotHandle(WrenVM*, int);

  // ETC
  void wrenGetVariable(WrenVM*, const char*, const char*, int);
}

enum WrenType {
  BOOL,
  NUM,
  FOREIGN,
  LIST,
  NULL,
  STRING,
  UNKNOWN
}

enum WrenInterpretResult {
  SUCCESS,
  COMPILE_ERROR,
  RUNTIME_ERROR
}

struct WrenVM {}
struct WrenHandle {}

struct WrenConfiguration {
  void* reallocateFn;
  void* loadModuleFn;
  void* bindForeignMethodFn;
  void* bindForeignClassFn;
  void* writeFn;
  void* errorFn;
  size_t initialHeapSize;
  size_t minHeapSize;
  int heapGrowthPercent;
  void* userData;
}
