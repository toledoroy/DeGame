//Track Addresses (Fill in present addresses to prevent new deplopyment)
const contractAddr: any = {
  rinkeby: {
      game:"0x4650e8FC59AbfD38B90712501225Fd19562C97AC",  //D2.91
      claim:"0xF1326573800a70bbeDF360eCF6cdfCbE20459945",  //D2.8
      task: "",
      hub:"0xadE0EE8E93bC6EeB87c7c5279B36eA7977fCAF96", //D4.6 (Proxy)
      avatar:"0x0665dfc970Bd599e08ED6084DC12B2dD028cC416",  //D2.8 (Proxy)
      history:"0xD7ab715a2C1e5b450b54B1E3cE5136D755c715B8", //D4.4 (Proxy)
  },
  mumbai:{
    game: "0x57d1469c53Bb259Dc876A274ADd329Eb703Ab286", // D2.91
    claim: "0xED7621062a097f95183edC753e185B4f75d4B637", // D2.8
    task: "",
    hub: "0x47307dEBB584C680E51dAFb167622ce9633c2Acf", // D4.6 (Proxy)
    avatar: "0xFe61dc25C3B8c3F990bCea5bb901704B2a8b9Bd2", // D2.8 (Proxy)
    history: "0x95BD98a656C907fC037aF87Ea740fD94188Cd65f", // D4.4 (Proxy)
  },
  optimism:{
  },
  optimism_kovan:{
    game: "0x086C1A95773a1ec76F5D8C7350B5D220cbcc640A",
    claim: "0xCC32bD878C0781800A38249Cdb206A844678E5F1",
    task: "",
    hub: "0x145b34E3BB516FBC47968984dbe0b463f03F32cF",
    avatar: "0x93f5D16e5c590849CdCb4c0CC5666C4c927c92B8",
    history: "0xce5F671e5e2C9c122e09Fe323aB0840155ab1D60",
  },
};

export default contractAddr;