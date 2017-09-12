car_troubleshooting.png: car_troubleshooting.dot
	dot car_troubleshooting.dot -Tpng > car_troubleshooting.png

car_troubleshooting.dot: flowchart.xsl DMC-FLWCHRT-A-00-00-00-00A-420A-D_EN-CA.XML
	xsltproc flowchart.xsl DMC-FLWCHRT-A-00-00-00-00A-420A-D_EN-CA.XML > car_troubleshooting.dot

clean:
	rm -f car_troubleshooting.png car_troubleshooting.dot
