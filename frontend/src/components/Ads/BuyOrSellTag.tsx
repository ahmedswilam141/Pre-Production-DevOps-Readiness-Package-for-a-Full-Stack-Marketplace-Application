import React from 'react';
export const BuyOrSellTag = ({ is_sell_ad }: { is_sell_ad?: boolean }) => { return <div>{is_sell_ad ? 'Sell' : 'Buy'}</div>; };
export default BuyOrSellTag;
