#!/bin/bash

cd /root/cardano-my-node/Cardano-NFT-Auto-Mint/
looping=1
log=log_file.txt
txs=txs.txt
numberCompleted=0
donationAddr=addr1qxh5mudsuqa86e5655e6g3m9chv234z5re0jfv7x3n38x0hduq5z7awms2hvxfsghtvchnc92xksnrn9yhuq0vjgss7s88mu6n
paymentAddr="Insert payment address here"
paymentSignKeyPath="Insert path to skey here"
policySignKeyPath="Insert path to skey here"
scriptPath="Insert path to script file here"
profitAddr="Insert profit address here"
echo "" >> $txs
echo "" >> $log
echo "Log File" >> $log
echo "-------------------" >> $log
echo "Process started at: $(date +%T)" >> $log
echo "-------------------" >> $log
echo "" >> $log

trap 'looping=0;wait' INT TERM

while (( looping )); do
    cardano-cli query utxo --address $paymentAddr --mainnet > fullUtxo.out
    tail -n +3 fullUtxo.out | sort -k3 -nr > balance.out
    cat balance.out
    while read -r utxo; do
        sleep 5s
        echo "UTXO detected" >> $log
        tx_hash=$(awk '{ print $1 }' <<< "${utxo}")
        idx=$(awk '{ print $2 }' <<< "${utxo}")
        utxo_balance=$(awk '{ print $3 }' <<< "${utxo}")
        tx_in="--tx-in ${tx_hash}#${idx}"
	if [ $( grep -q "${tx_hash}" "$txs" && echo $? ) ];
	then
	    echo "Previous tx" >> $log
	    break
	else
	    echo ${tx_hash} >> $txs
	    echo $(curl -H 'project_id: INSERT HERE' \
                https://cardano-mainnet.blockfrost.io/api/v0/txs/${tx_hash}/utxos \
                | jq '.inputs' | jq '.[0]' | jq '.address') >> $log
            in_addr=$(curl -H 'project_id: INSERT HERE' \
                https://cardano-mainnet.blockfrost.io/api/v0/txs/${tx_hash}/utxos \
                | jq '.inputs' | jq '.[0]' | jq '.address' | sed 's/^.//;s/.$//')
            echo "Address: ${in_addr}"
            if [ ${utxo_balance} != 50000000 ] || [ $(ls "metadata/" | wc -l) == 0 ];
    	    then
	        echo ${utxo_balance} >> $log
	        echo "Refund Initiated" >> $log
	        currentSlot=$(cardano-cli query tip --mainnet | jq -r '.slot')
                cardano-cli transaction build-raw \
                    --fee 0 \
                    ${tx_in} \
                    --tx-out ${in_addr}+${utxo_balance} \
                    --invalid-hereafter $(( ${currentSlot} + 10000)) \
                    --out-file tx.tmp >> $log
                fee=$(cardano-cli transaction calculate-min-fee \
                    --tx-body-file tx.tmp \
                    --tx-in-count 1 \
                    --tx-out-count 1 \
                    --mainnet \
                    --witness-count 1 \
                    --byron-witness-count 0 \
                    --protocol-params-file protocol.json | awk '{ print $1 }') >> $log
                fee=${fee%" Lovelace"}
                amountToSendUser=$(( ${utxo_balance}-${fee} ))
	        echo ${amountToSendUser} >> $log
                cardano-cli transaction build-raw \
                    --fee ${fee} \
                     ${tx_in} \
                    --tx-out ${in_addr}+${amountToSendUser} \
                    --invalid-hereafter $(( ${currentSlot} + 10000)) \
                    --out-file tx.raw >> $log
                cardano-cli transaction sign \
                    --signing-key-file $paymentSignKeyPath \
                    --tx-body-file tx.raw \
                    --out-file tx.signed \
                    --mainnet >> $log
                cardano-cli transaction submit --tx-file tx.signed --mainnet >> $log
            else
	        echo "Sending NFT" >> $log
         	numberCompleted=$(( numberCompleted+1 ))
	        POLICYID=$(cardano-cli transaction policyid --script-file $scriptPath)
                metadata_file=$(ls metadata/ | sort -R | tail -1)
                name=$(echo ${metadata_file} | awk '{ print substr( $0, 1, length($0)-5 ) }')
                amountToSendUser=1500000
	        amountToDonate=5000000
	        amountToSendProfit=43500000
                currentSlot=$(cardano-cli query tip --mainnet | jq -r '.slot')
                cardano-cli transaction build-raw \
                    --fee 0 \
                    ${tx_in} \
                    --tx-out ${in_addr}+${amountToSendUser}+"1 $POLICYID.${name}" \
                    --tx-out ${profitAddr}+${amountToSendProfit} \
		    --tx-out ${donationAddr}+${amountToDonate} \
		    --mint="1 $POLICYID.${name}" \
		    --minting-script-file $scriptPath \
		    --metadata-json-file ./metadata/${metadata_file} \
                    --invalid-hereafter $(( ${currentSlot} + 10000)) \
                    --out-file tx.tmp >> $log
                fee=$(cardano-cli transaction calculate-min-fee \
                    --tx-body-file tx.tmp \
                    --tx-in-count 1 \
                    --tx-out-count 3 \
                    --mainnet \
                    --witness-count 2 \
                    --byron-witness-count 0 \
                    --protocol-params-file protocol.json | awk '{ print $1 }') >> $log
	        fee=${fee%" Lovelace"}
                amountToSendUser=$((${amountToSendUser}-${fee}))
                cardano-cli transaction build-raw \
                    --fee ${fee} \
                    ${tx_in} \
                    --tx-out ${in_addr}+${amountToSendUser}+"1 $POLICYID.${name}" \
                    --tx-out ${profitAddr}+${amountToSendProfit} \
		    --tx-out ${donationAddr}+${amountToDonate} \
		    --mint="1 $POLICYID.${name}" \
                    --minting-script-file $scriptPath \
		    --metadata-json-file ./metadata/${metadata_file} \
                    --invalid-hereafter $(( ${currentSlot} + 10000)) \
                    --out-file tx.raw >> $log
                cardano-cli transaction sign \
                    --signing-key-file $paymentSignKeyPath \
	            --signing-key-file $policySignKeyPath \
                    --tx-body-file tx.raw \
                    --out-file tx.signed \
                    --mainnet >> $log
                cardano-cli transaction submit --tx-file tx.signed --mainnet >> $log
	        rm ./metadata/${metadata_file}
            fi
            rm tx.*
	    echo "" >> $log
        fi
    done < balance.out
    wait
done
