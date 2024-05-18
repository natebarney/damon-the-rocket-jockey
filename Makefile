PROGRAM=damon
MODULES= \
  loadaddr \
  loader \
  main \
  collision \
  animation \
  barrier \
  bullet \
  enemy \
  game \
  graphics \
  input \
  irq \
  level \
  mobile \
  music \
  palette \
  pellet \
  player \
  score \
  ship \
  sound \
  sprite \
  spritedata \
  tiledata \
  title \
  util \
  vera

DEPDIR=.deps

OUTPUT=$(addsuffix .prg,$(PROGRAM))
CONFIG=$(addsuffix .cfg,$(PROGRAM))
LABELS=$(addsuffix .lbl,$(PROGRAM))
MAPFILE=$(addsuffix .map,$(PROGRAM))
OBJECTS=$(addsuffix .o,$(MODULES))
LISTINGS=$(addsuffix .lst,$(MODULES))
DEPS=$(addprefix $(DEPDIR)/,$(addsuffix .d,$(MODULES)))

AS_FLAGS=--cpu 65c02 -g

all: $(DEPS) $(OUTPUT)

run: $(OUTPUT)
	x16emu -prg $(OUTPUT) -run

debug: $(OUTPUT)
	x16emu -prg $(OUTPUT) -run -debug 80d

$(OUTPUT): $(CONFIG) $(OBJECTS)
	ld65 -o $@ -Ln $(LABELS) -m $(MAPFILE) -C $^

$(DEPDIR)/%.d: %.s
	@mkdir -p $(DEPDIR)
	@python util/deps.py -o $@ $<

%.o: %.s
	ca65 $(AS_FLAGS) -l $(addsuffix .lst,$(basename $<)) -o $@ $<

clean:
	rm -f $(OUTPUT) $(LABELS) $(LISTINGS) $(MAPFILE) $(OBJECTS)

distclean: clean
	rm -rf $(DEPDIR)

.PHONY: all clean distclean run debug

-include $(DEPS)
