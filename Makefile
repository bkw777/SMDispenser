# Brian K. White - b.kenyon.w@gmail.com

.PHONY: all
all:
	${MAKE} -C scad clean
	${MAKE} -C scad -j4
	mv -vf scad/*.png pics/
	rm -f stl/*.stl
	mv -vf scad/*.stl stl/
