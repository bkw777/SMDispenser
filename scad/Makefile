# Generate STL output files from OpenSCAD source
# Brian K. White - b.kenyon.w@gmail.com

model = SMDispenser
variants = \
	caddy_40_8_1    \
	caddy_40_8_2    \
	caddy_60_8_1    \
	caddy_60_8_2    \
	caddy_60_12_2   \
	caddy_60_16_3   \
	caddy_120_16_3  \
	caddy_120_25_3  \
	caddy_120_33_4  \
	base_40_120_0   \
	base_60_120_0   \
	base_120_120_0  \
	base_40_120_15  \
	base_60_120_15  \
	base_120_120_15 \
#	cap_40          \
#	cap_60          \
#	cap_120         \

openscad = openscad-nightly
#openscad = openscad

.PHONY: all
all: $(variants) $(model).png

.PHONY: $(variants)
$(variants): %: $(model)_%.stl

# Generate STLs
$(model)_%.stl: $(model).scad
	@x="$(*)" ;\
	p=$${x%%_*} ;x=$${x#*_}; d=$${x%%_*} ;x=$${x#*_};\
	case "$$p" in\
	  "cap") $(openscad) -DPRINT=\"$${p}\" -Dspool_diameter=$${d} -o $(@) $(model).scad ;;\
	  "base") w=$${x%%_*} ;x=$${x#*_}; $(openscad) -DPRINT=\"$${p}\" -Dspool_diameter=$${d} -Dbase_length=$${w} -Dbase_tilt_angle=$${x} -o $(@) $(model).scad ;;\
	  "caddy") w=$${x%%_*} ;x=$${x#*_}; $(openscad) -DPRINT=\"$${p}\" -Dspool_diameter=$${d} -Dstrip_width=$${w} -Dstrip_thickness=$${x} -o $(@) $(model).scad ;;\
	esac

# Generate .png for README.md
$(model).png: $(model).scad
	$(openscad) -Dpreview_fully_populated=true -Dbase_tilt_angle=15 -Dspool_diameter=60 -Dstrip_width=8 -Dstrip_thickness=1 --colorscheme DeepOcean --imgsize 1024,768 --viewall -o $(@) $(model).scad

.PHONY: clean
clean:
	rm -f *.stl *.png
