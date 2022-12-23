#!/bin/bash

CP="default-v2.50.4-MT5.set"
CP_OUT=$CP-ansi.txt

cat $CP | tr -d '\0' > $CP_OUT

echo "#Convert TimeFrame"
for i in $(cat $CP_OUT) ; do
	value=$(echo $i | grep "Signal_TimeFrame" | cut -f1 -d"=")
	if [ $? -eq 0 ] ; then
		if [ ! -z $value ] ; then
			echo "if (!(ConvertTFMT5toMT4 -value "\"$value\"" -file \$Destino)) {"
			echo "	return [bool]\$false, '$value'"
			echo "}"
		fi
	fi

	value=$(echo $i | grep "_TF" | cut -f1 -d"=")
	if [ $? -eq 0 ] ; then
		if [ ! -z $value ] ; then
			echo "if (!(ConvertTFMT5toMT4 -value "\"$value\"" -file \$Destino)) {"
			echo "	return [bool]\$false, '$value'"
			echo "}"
		fi
	fi
done
echo " "
echo "#Convert Price"
for i in $(cat $CP_OUT) ; do
	value=$(echo $i | grep "Price" | grep -vi "ADX_Price" | cut -f1 -d"=")
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
echo "Set-OrAddIniValue -FilePath \$Destino  -keyValueList @{"
echo "	ADX_Price = \"0\""
echo "}"
echo " "
echo "#Convert Bool (true/false)"
for i in $(cat $CP_OUT | grep -i "=false" | cut -f1 -d"=") ; do
	echo ConvertBoolMT5toMT4 -value "\"$i\"" -file \$Destino
done

for x in $(cat $CP_OUT | grep "=true" | cut -f1 -d"=") ; do
	echo ConvertBoolMT5toMT4 -value "\"$x\"" -file \$Destino	
done
