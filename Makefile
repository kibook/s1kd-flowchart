PDF_PARAMS+=-param double.sided 0
PDF_PARAMS+=-param fop1.extensions 1
PDF_PARAMS+=-stringparam publication.code ''

all: car_troubleshooting.png DMC-FLWCHRT-A-00-00-00-00A-420A-D_EN-CA.pdf

car_troubleshooting.png: car_troubleshooting.dot
	dot car_troubleshooting.dot -Tpng > car_troubleshooting.png

car_troubleshooting.dot: flowchart.xsl DMC-FLWCHRT-A-00-00-00-00A-420A-D_EN-CA.XML
	xsltproc flowchart.xsl DMC-FLWCHRT-A-00-00-00-00A-420A-D_EN-CA.XML > car_troubleshooting.dot

DMC-FLWCHRT-A-00-00-00-00A-420A-D_EN-CA.pdf: DMC-FLWCHRT-A-00-00-00-00A-420A-D_EN-CA.XML
	s1kd2pdf DMC-FLWCHRT-A-00-00-00-00A-420A-D_EN-CA.XML $(PDF_PARAMS)

clean:
	rm -f car_troubleshooting.png car_troubleshooting.dot DMC-FLWCHRT-A-00-00-00-00A-420A-D_EN-CA.pdf
