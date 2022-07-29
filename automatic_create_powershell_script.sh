#!/bin/bash

echo "#Convert TimeFrame"
for i in $(cat cp2.48.txt) ; do
	value=$(echo $i | grep "Signal_TimeFrame" | cut -f1 -d"=")
	if [ $? -eq 0 ] ; then
		if [ ! -z $value ] ; then
			echo "if (!(ConvertTFMT5toMT4 -value "\"$value\"" -file \$Destino)) {"
			echo "	return [bool]\$false"
			echo "}"
		fi
	fi

	value=$(echo $i | grep "_TF" | cut -f1 -d"=")
	if [ $? -eq 0 ] ; then
		if [ ! -z $value ] ; then
			echo "if (!(ConvertTFMT5toMT4 -value "\"$value\"" -file \$Destino)) {"
			echo "	return [bool]\$false"
			echo "}"
		fi
	fi
done

echo " "
echo "#Convert Price"
for i in $(cat cp2.48.txt) ; do
	value=$(echo $i | grep "Price" | cut -f1 -d"=")
	if [ $? -eq 0 ] ; then
		if [ ! -z $value ] ; then
			if [ "$value" != "Oscillators_STO_Price" ] ; then
				if [ "$value" != "Oscillator2_STO_Price" ] ; then
					if [ "$value" != "Oscillator3_STO_Price" ] ; then
						if [ "$value" != "Open_PriceLabel_Width" ] ; then
							if [ "$value" != "Close_PriceLabel_Width" ] ; then
								echo ConvertPriceMT5toMT4 -value "\"$value\"" -file \$Destino
							fi
						fi
					fi
				fi
			fi
		fi
	fi
done
echo " "
echo "#Convert Bool (true/false)"
for i in $(cat cp2.48.txt) ; do
	value1=$(echo $i | grep "false" | cut -f1 -d"=")
	if [ $? -eq 0 ] ; then
		if [ ! -z $value1 ] ; then
			echo ConvertBoolMT5toMT4 -value "\"$value1\"" -file \$Destino
		fi
	fi
	value2=$(echo $i | grep "true" | cut -f1 -d"=")
	if [ $? -eq 0 ] ; then
		if [ ! -z $value2 ] ; then
			echo ConvertBoolMT5toMT4 -value "\"$value2\"" -file \$Destino
		fi
	fi
done
